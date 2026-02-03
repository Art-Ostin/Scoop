//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import Foundation

struct ProposedTimes: Codable, Equatable  {
    
    
    
    static let maxCount = 3
    
    private(set) var values: [Date]
    
    var dates: [Date] {
        values
    }
    
    init(values: [Date] = []) {
        self.values = Array(values.prefix(Self.maxCount))
    }
    
    mutating func updateDate(day: Date, hour: Int, minute: Int) {
        guard let parsedDate = parseDate(day: day, hour: hour, minute: minute) else {
            print("Error: Date not updated")
            return
        }
        if let existingIndex = indexOfDay(day),
           isSameMinute(values[existingIndex], parsedDate) {
            remove(day)
            return
        }
        remove(day)
        values.append(parsedDate)
        if values.count > Self.maxCount {
            values.removeFirst(values.count - Self.maxCount)
        }
    }
    
    mutating func addAndDeleteDate(date newDate: Date) {
        if values.count >= Self.maxCount {
            values.removeFirst()
        }
        values.append(newDate)
    }
    
    mutating func remove(_ date: Date) {
        values.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
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
        values = values.map { old in
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: old) ?? old
        }
    }
    
    private func indexOfDay(_ day: Date) -> Int? {
        values.firstIndex { Calendar.current.isDate($0, inSameDayAs: day) }
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
        try container.encode(values)
    }
}

