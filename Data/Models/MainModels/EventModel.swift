//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit
import FirebaseFirestore

struct EventDraft: Codable, Equatable {
    var initiatorId: String
    var recipientId: String
    var type: EventType
    var message: String?
    var proposedTimes: ProposedTimes = .init()
    var location: EventLocation?
}

struct Event: Identifiable, Codable {
    @DocumentID var _id: String?
    var id: String { _id! }
    var initiatorId: String
    var recipientId: String
    var type: EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var status: EventStatus = .pending
    var canText: Bool = false
    var message: String?
    var changeLog: [ChangeLogEntry] = []
    var earlyTerminatorID: String? // If event status is .cancelled or .neverShowed this field gives who is responsible to track e.g. how many 'cancel's or 'no shows.
    @ServerTimestamp var date_created: Date?
    
    enum Field: String {
        case id, initiatorId, recipientId, type, message, date_created, time, location, status, invite_expiry_time, earlyTerminatorID
    }
    
    init(draft: EventDraft) {
        self.initiatorId = draft.initiatorId
        self.recipientId = draft.recipientId
        self.type = draft.type
        self.proposedTimes = draft.proposedTimes
        self.location = draft.location ?? EventLocation(mapItem: MKMapItem())
        //Starting Values
        self.status = .pending
        self.canText = false
    }
}

struct UserEvent: Identifiable, Codable {

    @DocumentID var id: String?
    let otherUserId: String
    let role: EdgeRole
    let status: EventStatus
    let proposedTimes: ProposedTimes
    var acceptedTime: Date?
    let type: EventType
    let message: String?
    let place: EventLocation
    let otherUserName: String
    let otherUserPhoto: String
    let updatedAt: Date?
    var canMessage: Bool = false
    var earlyTerminatorID: String?
    
    enum Field: String, Codable {
        case id, otherUserId, role, status, proposedTimes, acceptedTime, type, message, place, otherUserName, otherUserPhoto, updatedAt, earlyTerminatorID, canMessage
    }
}

enum EventStatus: String, Codable, Equatable { case pending, accepted, declined, declinedTimePassed,pastAccepted, cancelled, neverShowed }

enum EventScope { case upcomingInvited, upcomingAccepted, pastAccepted }

enum EdgeRole: String, Codable { case sent, received }

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
            return "E.g. My friends instagram is @, let do a double dateee if you're down!"
        case .socialMeet:
            return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
        case .custom:
            return "E.g. Throwing a house party on Friday, you should come along with your friends"
        }
    }
}


