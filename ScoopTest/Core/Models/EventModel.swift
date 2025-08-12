//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit
import FirebaseFirestore



struct EventArray : Codable {
    let events: [Event]
    let total, skip, limit: Int
}

enum EventStatus: String, Codable{
    case pending
    case accepted
    case declined
    case cancelled
}

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var initiatorId: String? 
    var recipientId: String?
    var type: String?
    var message: String?
    @ServerTimestamp var date_created: Date?
    var time: Date?
    var location: EventLocation?
    var status: EventStatus = .accepted
    
    enum CodingKeys: CodingKey {
        case id
        case initiatorId
        case recipientId
        case type
        case message
        case date_created
        case time
        case location
        case status
    }
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
