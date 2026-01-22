//
//  EventFormatting.swift
//  Scoop
//
//  Created by Art Ostin on 22/01/2026.
//

 import SwiftUI


 public enum EventFormatting {
     
     static func dayAndTime(_ event: UserEvent) -> String {
         let date = event.time
         let dayPart = date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
         let timePart = date.formatted(.dateTime.hour().minute())
         return "\(dayPart) · \(timePart)"
     }
     
     static func placeName(_ event: UserEvent) -> String {
         event.place.name
         ?? event.place.address.map { String($0.prefix(20)) }
         ?? ""
     }
     
     static func placeFullAddress( event: UserEvent) -> String {
         (event.place.name ?? "") + " " + (event.place.address ?? "")
     }
 }
