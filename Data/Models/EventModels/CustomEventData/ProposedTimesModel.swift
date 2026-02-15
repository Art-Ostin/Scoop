//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import Foundation

struct ProposedTime: Codable, Equatable {
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
        dates.sort { $0.date > $1.date }
        if dates.count > Self.maxCount {
            dates = Array(dates.prefix(Self.maxCount))
        }
    }
    
    private static func parseDate(day: Date, hour: Int, minute: Int, calendar: Calendar) -> Date? {
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)
    }
}



/*
 private func parseDate(day: Date, hour: Int, minute: Int) -> Date? {
     var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
     components.hour = hour
     components.minute = minute
     guard let date = Calendar.current.date(from: components) else { return nil }
     return date
 }

 */
