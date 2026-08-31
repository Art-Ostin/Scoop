//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import Foundation

//A wall-clock time with no day attached — the one time-of-day an invite's proposed days share.
struct TimeOfDay: Codable, Equatable, Hashable {

    var hour: Int
    var minute: Int

    static let `default` = TimeOfDay(hour: 21, minute: 30)

    var minutesFromMidnight: Int { hour * 60 + minute }

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? Self.default.hour, minute: parts.minute ?? Self.default.minute)
    }

    //`bySettingHour` matches forward, so a time skipped by DST resolves to the next valid one rather than nil.
    func applied(to day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}

struct ProposedTime: Codable, Equatable, Hashable {
    var date: Date
    var stillAvailable: Bool = true
    //Which of the invite's days this is: 1 is the closest. Stamped by ProposedTimes, never
    //set at a call site — the default is only what a lone ProposedTime holds until it joins a set.
    var optionNumber: Int = 1

    enum CodingKeys: String, CodingKey { case date, stillAvailable, optionNumber }
}

//In an extension on purpose: an initializer written in the struct body would suppress the
//memberwise init, and `.init(date:)` is called from four places.
extension ProposedTime {

    //LOAD-BEARING. A field added after the first invites were written must decode if-present:
    //the synthesised decoder throws keyNotFound on a document that predates it, and
    //FirestoreService.streamCollection turns that into finish(throwing:) — one old invite takes
    //down the whole events stream, so nothing loads at all.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        stillAvailable = try container.decodeIfPresent(Bool.self, forKey: .stillAvailable) ?? true
        optionNumber = try container.decodeIfPresent(Int.self, forKey: .optionNumber) ?? 0
    }
}

struct ProposedTimes: Codable, Equatable, Hashable  {
    
    static let maxCount = 3
    private(set) var dates: [ProposedTime]
    
    
    init(items: [ProposedTime] = []) {
        self.dates = items
        normalize()
    }
    
    //The available times themselves, still carrying their option number — availableDates()
    //throws it away, and a screen labelling a day's card needs it.
    func availableTimes() -> [ProposedTime] {
        dates
            .filter(\.stillAvailable)
            .sorted { $0.date < $1.date }
    }

    func availableDates() -> [Date] {
        availableTimes().map(\.date)
    }
    
    var firstAvailableDate: Date? {
        availableDates().first
    }
    var lastProposedDate: Date {
        dates.last?.date ?? .distantPast
    }
    
    var hourText: String? {
        guard let date = dates.first?.date else { return nil }
        return FormatEvent.hourTime(date)
    }
    
    @discardableResult
    mutating func updateDate(day: Date, hour: Int, minute: Int) -> Bool {
        let cal = Calendar.current
        
        if let idx = dates.firstIndex(where: { cal.isDate($0.date, inSameDayAs: day) }) {
            dates.remove(at: idx)
            normalize() //Removing the middle day would otherwise leave the numbering at 1, 3
            return false
        }
        
        guard dates.count < Self.maxCount,
              let parsed = Self.parseDate(day: day, hour: hour, minute: minute, calendar: cal)
        else { return true }
        
        dates.append(.init(date: parsed))
        normalize()
        return false
    }
    
    mutating func remove(_ day: Date) {
        let cal = Calendar.current
        dates.removeAll { cal.isDate($0.date, inSameDayAs: day) }
        normalize()
    }

    //A stored draft outlives the times it proposed — drop every one that has already passed.
    //Instant-based, not day-based: today is a day the picker offers, so a proposal for today
    //at 21:30 stays valid until 21:30. True if anything went.
    @discardableResult
    mutating func removePastTimes(now: Date = .now) -> Bool {
        let before = dates.count
        dates.removeAll { $0.date <= now }
        normalize()
        return dates.count != before
    }
    
    //Combines selected day and hour (and minute) into one date to update day
    mutating func updateTime(hour: Int, minute: Int) {
        let cal = Calendar.current
        for i in dates.indices {
            dates[i].date = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dates[i].date) ?? dates[i].date
        }
        normalize()
    }
    
    func contains(day: Date) -> Bool {
        let number = dates.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return number != nil
    }
    
    private mutating func normalize() {
        dates.sort { $0.date < $1.date }
        if dates.count > Self.maxCount {
            dates = Array(dates.prefix(Self.maxCount))
        }
        stampOptionNumbers()
    }

    //Option numbers are positional for now — the closest day is 1. When the sender can choose
    //their own order this becomes "keep what was chosen, fill the gaps". It is the only place
    //that decides, so nothing downstream changes when that lands.
    private mutating func stampOptionNumbers() {
        for i in dates.indices { dates[i].optionNumber = i + 1 }
    }
    
    private static func parseDate(day: Date, hour: Int, minute: Int, calendar: Calendar) -> Date? {
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)
    }
    
}

//How close to a proposed time the other side stops being able to accept. One constant, so the
//list that draws a day, the list that calls the invite expired, and the copy explaining the
//rule can't drift apart.
extension ProposedTimes {

    static let acceptanceLead: TimeInterval = 4 * 60 * 60

    //The days still worth offering: available, and far enough out to still be accepted.
    func acceptableTimes(asOf now: Date = .now) -> [ProposedTime] {
        availableTimes().filter { $0.date > now.addingTimeInterval(Self.acceptanceLead) }
    }

    //Every day it proposed has fallen inside the acceptance window. An invite carrying no days
    //at all is expired too, which is what the empty set already gives.
    func isExpired(asOf now: Date = .now) -> Bool {
        acceptableTimes(asOf: now).isEmpty
    }
}

//Where an invite written before option numbers existed gets them: every entry decodes to the
//same fallback, and normalize() re-stamps the set in date order so its days read 1, 2, 3.
extension ProposedTimes {

    enum CodingKeys: String, CodingKey { case dates }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dates = try container.decode([ProposedTime].self, forKey: .dates)
        normalize()
    }
}

//To format Multiple days
extension ProposedTimes {
    
    //Days sharing a month name it once, at the end of their run: "Wed 30 Jul, Sun 3 or Mon 4 Aug · 21:30"
    func formatMultipleInvitedDays() -> String {
        invitedDayPieces().map(\.text).joined()
    }

    //The one day a surface names when it has no room for the run: "Fri 4 Sep · 21:30". It is the
    //same day RespondDraft preselects (firstAvailableDate), NOT the first still-acceptable one —
    //so the invite card and the respond popup that grows out of it can never name different days.
    //Every day lapsed still reads as the first proposed rather than going blank.
    func formatFirstInvitedDay() -> String {
        guard let date = firstAvailableDate ?? dates.first?.date else { return "" }
        return FormatEvent.shortDayAndTime(date)
    }

    //The same line split day by day, each piece knowing whether its day can still be accepted —
    //for the row that keeps ink on the days still open and fades the ones that have lapsed.
    //The shared hour is the tail piece, never lapsed: it belongs to whichever days remain.
    func invitedDayPieces(asOf now: Date = .now) -> [(text: String, lapsed: Bool)] {
        guard !dates.isEmpty else { return [] }
        let acceptable = acceptableTimes(asOf: now)

        var pieces = dates.indices.map { index in
            (text: FormatEvent.shortDayAndTime(dates[index].date, withHour: false, withMonth: endsMonthRun(at: index))
                + daySuffix(at: index, dayCount: dates.count),
             lapsed: !acceptable.contains(dates[index]))
        }
        pieces.append((text: " · " + FormatEvent.hourTime(lastProposedDate), lapsed: false))
        return pieces
    }

    //Whether every proposed day strikes the same clock time — the case the single trailing
    //hour can speak for. When it can't, each day has to carry its own.
    var sharesOneHour: Bool {
        Set(dates.map { FormatEvent.hourTime($0.date) }).count <= 1
    }

    //One piece per day, each wearing its own hour — for the card that shows days whose hours
    //differ: "Wed 30 Jul · 19:00" / "Sun 3 Aug · 21:30". Each line reads alone, so every day
    //names its month rather than sharing one at the end of a run.
    func invitedDayHourPieces(asOf now: Date = .now) -> [(text: String, lapsed: Bool)] {
        let acceptable = acceptableTimes(asOf: now)
        return dates.map { time in
            (text: FormatEvent.shortDayAndTime(time.date), lapsed: !acceptable.contains(time))
        }
    }

    //The same days as a record rather than an open offer: every day comma-joined, and the last
    //day's month lifted out of the list to sit with the time — "Sat 15, Tue 18, Thu 20 · Aug 22:30".
    //An earlier month still names itself, so a set straddling the boundary reads
    //"Thu 30 Jul, Mon 3 · Aug 22:30". Past tense, so no day is a choice and nothing joins with "or".
    func formatInvitedDaysList() -> String {
        guard let last = dates.last else { return "" }

        let days = dates.indices.map { index in
            //The last day's month is the one that moves to the tail; earlier runs keep naming their own
            let namesMonth = index != dates.count - 1 && endsMonthRun(at: index)
            return FormatEvent.shortDayAndTime(dates[index].date, withHour: false, withMonth: namesMonth)
        }
        .joined(separator: ", ")

        let month = last.date.formatted(.dateTime.month(.abbreviated))
        return "\(days) · \(month) \(FormatEvent.hourTime(last.date))"
    }

    //The same line split around its last day, for the expired card that flies it between rows:
    //the days before it (each carrying its separator), the last day spelled exactly as the
    //collapsed row spells it (Today/Tomorrow included — the flying text must read the same in
    //both perches), and the hour it gains when the drawer opens.
    func splitMultipleInvitedDays(withToday: Bool = true) -> (leadingDays: String, lastDay: String, hour: String) {
        let leading = dates.indices.dropLast().map { index in
            FormatEvent.shortDayAndTime(dates[index].date, withHour: false, withMonth: endsMonthRun(at: index))
                + daySuffix(at: index, dayCount: dates.count)
        }
        .joined()

        return (leading,
                FormatEvent.shortDayAndTime(lastProposedDate, withHour: false, withToday: withToday),
                FormatEvent.hourTime(lastProposedDate))
    }

    //A day names its month only when the next one leaves it — dates are sorted, so a month's days sit together
    private func endsMonthRun(at index: Int) -> Bool {
        let next = index + 1
        guard next < dates.count else { return true }
        return !Calendar.current.isDate(dates[index].date, equalTo: dates[next].date, toGranularity: .month)
    }

    private func daySuffix(at index: Int, dayCount: Int) -> String {
        guard index < dayCount - 1 else {
            return ""
        }
        
        return index == dayCount - 2 ? " or " : ", "
    }
}

//What the invite composer holds: up to 3 days plus the single time-of-day they all share.
//Instants are produced on demand, so no two days can ever disagree about the time.
struct TimeSelection: Codable, Equatable {

    static let maxCount = ProposedTimes.maxCount

    var timeOfDay: TimeOfDay = .default
    private(set) var days: [Date] = []   //start-of-day, sorted

    var proposedTimes: ProposedTimes {
        ProposedTimes(items: days.map { .init(date: timeOfDay.applied(to: $0)) })
    }

    var isEmpty: Bool { days.isEmpty }
    var count: Int { days.count }

    func contains(day: Date) -> Bool {
        days.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    //Adds the day, or removes it when already selected. True means the tap was rejected at the max.
    @discardableResult
    mutating func toggle(day: Date) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)

        if let idx = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: start) }) {
            days.remove(at: idx)
            return false
        }

        guard days.count < Self.maxCount else { return true }
        days.append(start)
        days.sort()
        return false
    }
}
