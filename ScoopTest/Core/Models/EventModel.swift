//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit


enum Status: Codable{
    case pending
    case accepted
    case declined
    case cancelled
}


struct Event: Identifiable, Codable {
    var id = UUID().uuidString
    var profile1_id: String?
    var profile2_id: String?
    var type: String?
    var message: String?
    var date_created: Date?
    var time: Date?
    var location: EventLocation?
    var status: Status?
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

