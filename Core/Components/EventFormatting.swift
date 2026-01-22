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
     
     static func placeName(_ place: EventLocation) -> String {
         place.name
         ?? place.address.map { String($0.prefix(20)) }
         ?? ""
     }
     
     static func placeFullAddress( place: EventLocation) -> String {
         (place.name ?? "") + " " + (place.address ?? "")
     }
 }
