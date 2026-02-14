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
        self.dates = Array(items.sorted { $0.date > $1.date }.prefix(Self.maxCount))
    }
    
    @discardableResult
    mutating func updateDate(day: Date, hour: Int, minute: Int) -> Bool {
        if contains(day: day) {
            remove(day)
            return false
        }
        if dates.count >= Self.maxCount { return true }
        guard let parsedDate = parseDate(day: day, hour: hour, minute: minute) else { return true }
        dates.append(ProposedTime(date: parsedDate))
        dates.sort { $0.date > $1.date }
        dates = Array(dates.prefix(Self.maxCount))
        return false
    }
    
    mutating func remove(_ date: Date) {
        dates.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
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
            var copy = old
            copy.date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: old.date) ?? old.date
            return copy
        }
        dates.sort { $0.date > $1.date }
    }
    
    func contains(day: Date) -> Bool {
        let number = dates.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return number != nil
    }
}
