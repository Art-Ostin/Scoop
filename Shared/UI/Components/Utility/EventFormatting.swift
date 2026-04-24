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
