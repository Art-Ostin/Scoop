//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit



struct Event: Identifiable {
    var id = UUID()
    var profile: UserProfile
    var profile2: UserProfile
    var type: EventType?
    var time: Date?
    var location: MKMapItem?
    var message: String?
}






















enum EventType: CaseIterable, Codable {
    case grabFood
    case grabADrink
    case houseParty
    case doubleDate
    case samePlace
    case writeAMessage
}


extension EventType {
    var description: (emoji: String?, label: String) {
        switch self {
        case .grabFood:
            return ("🍕", "Grab Food")
        case .grabADrink:
            return ("🍻", "Grab a Drink")
        case .houseParty:
            return ("🎉", "House Party")
        case .doubleDate:
            return ("🎑", "Double Date")
        case .samePlace:
            return ("🕺🏻", "Same Place")
        case .writeAMessage:
            return ("✒️", "Write a Message")
        }
    }
}

