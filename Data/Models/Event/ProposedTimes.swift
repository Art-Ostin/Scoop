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
}

struct ProposedTimes: Codable, Equatable  {
    
    static let maxCount = 3
    private(set) var dates: [ProposedTime]
    
    
    init(items: [ProposedTime] = []) {
        self.dates = items
        normalize()
    }
    
    func availableDates() -> [Date] {
        dates
            .filter(\.stillAvailable)
            .sorted { $0.date < $1.date }
            .map(\.date)
    }
    
    var firstAvailableDate: Date? {
        availableDates().first
    }
    
    @discardableResult
    mutating func updateDate(day: Date, hour: Int, minute: Int) -> Bool {
        let cal = Calendar.current
        
        if let idx = dates.firstIndex(where: { cal.isDate($0.date, inSameDayAs: day) }) {
            dates.remove(at: idx)
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
    }
    
    private static func parseDate(day: Date, hour: Int, minute: Int, calendar: Calendar) -> Date? {
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)
    }
    
}

//To format Multiple days
extension ProposedTimes {
    
    func formatMultipleInvitedDays() -> String {
    
        let value: String = {
            if dates.count == 1, let day = dates.first {
                return FormatEvent.dayAndTime(day.date)
            }
            return dates.indices.map { index in
                let day = dates[index]
                let isLast = index == dates.count - 1
                
                return FormatEvent.shortDayAndTime(day.date, withHour: isLast) + daySuffix(at: index, dayCount: dates.count)
            }
            .joined()
        }()
        return value
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
