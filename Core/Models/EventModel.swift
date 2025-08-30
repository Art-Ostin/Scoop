//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit
import FirebaseFirestore

struct EventDraft {
    
    var initiatorId: String = ""
    var recipientId: String = ""
    var type: String = ""
    var message: String?
    var time: Date = Date()
    var location: EventLocation = EventLocation(mapItem: MKMapItem())
    var status: EventStatus = .pending
    var inviteExpiryTime: Date = Date().addingTimeInterval(60 * 60 * 24)
    var canText: Bool = false
    
    enum Field: String {
        case id, initiatorId, recipientId, type, message, date_created, time, location, status, invite_expiry_time
    }
}


struct Event: Identifiable, Codable {
    @DocumentID var _id: String?
    var id: String { _id! }
    var initiatorId: String
    var recipientId: String
    var type: String
    var time: Date
    var location: EventLocation
    var status: EventStatus = .pending
    var inviteExpiryTime: Date
    var canText: Bool = false
    
    @ServerTimestamp var date_created: Date?
    var message: String?
}

extension Event {
    init(draft: EventDraft) {
        self.init(
            initiatorId: draft.initiatorId,
            recipientId: draft.recipientId,
            type: draft.type,
            time: draft.time,
            location: draft.location,
            status: draft.status,
            inviteExpiryTime: draft.inviteExpiryTime,
            canText: draft.canText
        )
    }
}






enum EventStatus: String, Codable { case pending, accepted, declined, declinedTimePassed, cancelled, pastAccepted }

enum EventScope { case upcomingInvited, upcomingAccepted, pastAccepted }

enum EventType: CaseIterable, Codable {
    case grabFood, grabADrink, houseParty, doubleDate, samePlace, writeAMessage
    
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

