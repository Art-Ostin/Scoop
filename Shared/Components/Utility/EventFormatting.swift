//
//  EventFormatting.swift
//  Scoop
//
//  Created by Art Ostin on 22/01/2026.
//

import Foundation

public enum FormatEvent {
    
    //Format event Time
    static func dayAndTime(_ date: Date, wide: Bool = true, withHour: Bool = true, monthWide: Bool = true) -> String {
        let cal = Calendar.current
        let hour = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))

        let dayPart: String
        if cal.isDateInToday(date) {
            dayPart = "Today"
        } else if cal.isDateInTomorrow(date) {
            dayPart = "Tomorrow"
        } else {
            let weekday = date.formatted(.dateTime.weekday(wide ? .wide : .abbreviated))
            let monthDay = date.formatted(.dateTime.month(wide && monthWide ? .wide : .abbreviated).day())
            dayPart = "\(weekday), \(monthDay)"
        }
        return withHour ? "\(dayPart) · \(hour)" : dayPart
    }
    
    
    static func hourTime(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
    
    //Format event Place
    static func placeName(_ place: EventLocation) -> String {
        place.name
        ?? place.address.map { String($0.prefix(20)) }
        ?? ""
    }
    
    static func addressWithoutCountry(_ address: String?) -> String {
        guard let address else { return "Event Venue" }
        guard let i = address.lastIndex(of: ",") else { return address }
        return String(address[..<i]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    static func messageTime(_ date: Date, withToday: Bool = true) -> String {
        let cal = Calendar.current
        
        //1. Case 1: If date is same day as today, return time
        if cal.isDateInToday(date) && withToday {
            return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        }
        
        //2. Case 2: If Date is yesterday, return 'Yesterday'
        else if cal.isDateInYesterday(date) && withToday  {
            return "Yesterday"
        }
        
        //3. Case 3: If Date is within this week, return the Day of week
        else if cal.isDate(date, equalTo: .now, toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        }
        
        //4/ Case 4: If it is not today, yesterday, or this week, it is longer in past. Then return date in 15/08/2026 format
        else {
            return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
        }
    }
}
