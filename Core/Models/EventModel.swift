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
    var initiatorId: String?
    var recipientId: String?
    var type: EventType?
    var message: String?
    var time: Date?
    var location: EventLocation?
    var status: EventStatus = .pending
    var inviteExpiryTime: Date?
    var canText: Bool = false
}


struct Event: Identifiable, Codable {
    @DocumentID var _id: String?
    var id: String { _id! }
    var initiatorId: String
    var recipientId: String
    var type: EventType
    var time: Date
    var location: EventLocation
    var status: EventStatus = .pending
    var inviteExpiryTime: Date
    var canText: Bool = false
    
    var message: String?
    @ServerTimestamp var date_created: Date?
    
    enum Field: String {
        case id, initiatorId, recipientId, type, message, date_created, time, location, status, invite_expiry_time
    }
}


extension Event {
    init(draft: EventDraft) {
        self.init(
            initiatorId: draft.initiatorId ?? "",
            recipientId: draft.recipientId ?? "",
            type: draft.type ?? .custom,
            time: draft.time ?? Date(),
            location: draft.location ?? EventLocation(mapItem: MKMapItem()),
            status: draft.status,
            inviteExpiryTime:  draft.inviteExpiryTime ?? Date().addingTimeInterval(24 * 60 * 60),
            canText: draft.canText
        )
    }
}

enum EventStatus: String, Codable { case pending, accepted, declined, declinedTimePassed, cancelled, pastAccepted }

enum EventScope { case upcomingInvited, upcomingAccepted, pastAccepted }

enum EventType: String, CaseIterable, Codable, Hashable {
    case socialMeet, doubleDate, drink, custom
    
    var description: (emoji: String?, label: String) {
        switch self {
        case .drink:
            return ("🍻", "Grab a Drink")
        case .doubleDate:
            return ("🎑", "Double Date")
        case .socialMeet:
            return ("🕺🏻", "Same Place")
        case .custom:
            return ("✒️", "Write a Message")
        }
    }
}



/*
 case .grabFood:
     return ("🍕", "Grab Food")
 */
