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

enum EventStatus: String, Codable {
    case pending, accepted, declined, declinedTimePassed, cancelled, pastAccepted
}

enum EventScope {
    case upcomingInvited, upcomingAccepted, pastAccepted
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
    var status: EventStatus = .pending 
    var inviteExpiryTime: Date?
    
    enum Field: String {
        case id, initiatorId, recipientId, type, message, date_created, time, location, status, invite_expiry_time
    }
}


enum EventType: CaseIterable, Codable {
    case grabFood
    case grabADrink
    case houseParty
    case doubleDate
    case samePlace
    case writeAMessage
    
    
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

