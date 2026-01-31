//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

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
        //1: Get the date in the correct calendar format
        if let parsedDate = parseDate(day: day, hour: hour, minute: minute) {
            
            //2: If the date already present remove it from the values
            if values.contains(parsedDate) {
                remove(parsedDate)
                
            //3: If there are less than three dates, add it to the values
            } else if values.count < Self.maxCount {
                values.append(parsedDate)
                
            //4: If there already 3 values, delete the first date and add the new one
            } else {
                addAndDeleteDate(date: parsedDate)
            }
        } else {
            print("Error: Date not updated")
        }
    }
    
    mutating func addAndDeleteDate(date newDate: Date) {
        guard values.count == 3 else { return }
        values.removeFirst()
        values.append(newDate)
    }
    
    mutating func remove(_ date: Date) {
        values.removeAll {$0 == date }
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
    
    //Use these dates for seeing the availble dates
    func getDatesStillAvailble () -> [Date] {
        return [Date()]
    }
    func getExpiredDates () -> [Date] {
        return [Date()]
    }
    
    //Don't worry about understanding Yet
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode([Date].self)
        try self.init(from: decoded as! Decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

