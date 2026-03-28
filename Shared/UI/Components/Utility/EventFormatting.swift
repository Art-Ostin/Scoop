//
//  EventFormatting.swift
//  Scoop
//
//  Created by Art Ostin on 22/01/2026.
//

import Foundation

public enum FormatEvent {
    
    //Format event Time
    static func dayAndTime(_ date: Date, wide: Bool = true, withHour: Bool = true) -> String {
        let day = date.formatted( .dateTime .weekday(wide ? .wide : .abbreviated).day())
        let month = date.formatted(.dateTime.month(wide ? .wide : .abbreviated))
        let hour = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        
        return withHour ? "\(day) \(month) · \(hour)" : "\(day) \(month)"
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
}

/*
 
 private static func ordinalSuffix(for day: Int) -> String {
     let mod100 = day % 100
     if (11...13).contains(mod100) { return "th" }

     switch day % 10 {
     case 1: return "st"
     case 2: return "nd"
     case 3: return "rd"
     default: return "th"
     }
 }

 
 
      
 static func fullDate(_ date: Date, wideMonth: Bool = false) -> String {
         let weekday = date.formatted(.dateTime.weekday(.wide))
     let month = date.formatted(.dateTime.month(wideMonth ? .wide : .abbreviated))

     return "\(weekday) \(ordinalDay(for: date)) \(month)"
 }
 
 
 //Thursday 2 Apr
 static func expandedDate(_ date: Date) -> String {
     let weekday = date.formatted(.dateTime.weekday(.wide))
     let month = date.formatted(.dateTime.month(.wide).day())

     return "\(weekday) \(ordinalDay(for: date)) \(month)"
 }
 
 static func twoDigitHour(_ date: Date) -> String {
     return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
 }
 
 static func fullDateAndTime(_ date: Date) -> String {
     let weekday = date.formatted(.dateTime.weekday(.wide))
     let month = date.formatted(.dateTime.month(.wide))
     let time = hourTime(date)

     return "\(weekday), \(month) \(ordinalDay(for: date)) · \(time)"
 }

 private static func ordinalDay(for date: Date) -> String {
     let day = Calendar.current.component(.day, from: date)
     return "\(day)\(ordinalSuffix(for: day))"
 }
 */
