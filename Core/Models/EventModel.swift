//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit
import FirebaseFirestore

struct EventDraft: Equatable {
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
    var earlyTerminatorID: String? // If event status is .cancelled or .neverShowed this field gives who is responsible to track e.g. how many 'cancel's or 'no shows.
    @ServerTimestamp var date_created: Date?
    
    enum Field: String {
        case id, initiatorId, recipientId, type, message, date_created, time, location, status, invite_expiry_time, earlyTerminatorID
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

enum EventStatus: String, Codable, Equatable { case pending, accepted, declined, declinedTimePassed,pastAccepted, cancelled, neverShowed }

enum EventScope { case upcomingInvited, upcomingAccepted, pastAccepted }




//Add the images and functions of event details all here.
enum EventType: String, CaseIterable, Codable, Hashable {
    case drink, doubleDate, socialMeet, custom
    
    var description: (emoji: String?, label: String) {
        switch self {
        case .drink:
            return ("🍻", "Drink")
        case .doubleDate:
            return ("🎑", "Double Date")
        case .socialMeet:
            return ("🪩", "Social")
        case .custom:
            return ("✒️", "Custom")
        }
    }
    
    var title: String {
        switch self {
        case . drink:
            return "Drink"
        case .doubleDate:
            return "Double Date"
        case .socialMeet:
            return "Social"
        case .custom:
            return "Custom Meet"
        }
    }
    
    var textPlaceholder: String {
        switch self {
        case . drink:
            return "E.g. Lets get a drink"
        case .doubleDate:
            return "E.g. My friends instagram is @, let do a double dateee if you're dow!"
        case .socialMeet:
            return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
        case .custom:
            return "E.g. Throwing a house party on Friday, you should come along with your friends"
        }
    }
}



/*
 case .grabFood:
     return ("🍕", "Grab Food")
 */
