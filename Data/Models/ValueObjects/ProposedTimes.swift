//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import Foundation

struct ProposedTimes: Codable, Equatable  {

    static let maxCount = 3
    private(set) var dates: [Date]
    
    
    init(values: [Date] = []) {
        self.dates = Array(values.prefix(Self.maxCount))
    }
    
    mutating func updateDate(day: Date, hour: Int, minute: Int) {
        guard let parsedDate = parseDate(day: day, hour: hour, minute: minute) else { return }

        if let existingIndex = indexOfDay(day), isSameMinute(dates[existingIndex], parsedDate) {
            remove(day)
            return
        }
        remove(day)
        
        dates.append(parsedDate)
        
        if dates.count > Self.maxCount {
            dates.removeFirst(dates.count - Self.maxCount)
        }
    }
        
    mutating func remove(_ date: Date) {
        dates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    private func parseDate(day: Date, hour: Int, minute: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        guard let date = Calendar.current.date(from: components) else { return nil }
        return date
    }
    
    mutating func updateTime(hour: Int, minute: Int) {
        let calendar = Calendar.current
        dates = dates.map { old in
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: old) ?? old
        }
    }
    
    private func indexOfDay(_ day: Date) -> Int? {
        dates.firstIndex { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    private func isSameMinute(_ lhs: Date, _ rhs: Date) -> Bool {
        Calendar.current.isDate(lhs, equalTo: rhs, toGranularity: .minute)
    }

    func contains(day: Date) -> Bool {
        indexOfDay(day) != nil
    }
    
    //Don't worry about understanding Yet
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode([Date].self)
        self.init(values: decoded)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dates)
    }
}
