//
//  EventFormatting.swift
//  Scoop
//
//  Created by Art Ostin on 22/01/2026.
//

import Foundation

 public enum EventFormatting {
     
     static func dayAndTime(_ date: Date) -> String {
         let dayPart = date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
         let timePart = date.formatted(.dateTime.hour().minute())
         return "\(dayPart) · \(timePart)"
     }
     
     
     static func fullDate(_ date: Date) -> String {
             let weekday = date.formatted(.dateTime.weekday(.wide))
             let month = date.formatted(.dateTime.month(.abbreviated))

             let day = Calendar.current.component(.day, from: date)
             return "\(weekday) \(day)\(ordinalSuffix(for: day)) \(month)"
     }
     
     static func expandedDate(_ date: Date) -> String {
         let weekday = date.formatted(.dateTime.weekday(.wide))
         let month = date.formatted(.dateTime.month(.wide))

         let day = Calendar.current.component(.day, from: date)
         return "\(weekday) \(day)\(ordinalSuffix(for: day)) \(month)"
     }
          
     
     static func placeName(_ place: EventLocation) -> String {
         place.name
         ?? place.address.map { String($0.prefix(20)) }
         ?? ""
     }
     
     static func placeFullAddress( place: EventLocation) -> String {
        (place.address ?? "")
     }
     
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
 }


