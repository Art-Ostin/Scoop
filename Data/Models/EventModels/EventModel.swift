//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit
import FirebaseFirestore

struct Event: Identifiable, Codable {
    
    enum EventStatus: String, Codable, Equatable {
        case pending, accepted, declined, declinedTimePassed,pastAccepted, cancelled, neverShowed
    }
    
    enum EventScope: String, Codable {
        case upcomingInvited, upcomingAccepted, pastAccepted
    }
        
    enum EventType: String, CaseIterable, Codable, Hashable {
        case drink, doubleDate, socialMeet, custom
    }
        
    //1: Event Identifiers
    @DocumentID var _id: String?
    var id: String { _id! } //To just get a non optional ID
    var initiatorId: String
    var recipientId: String
    
    //2: Event Information
    var type: EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var message: String?
    
    //3: Event updatable Information
    var status: EventStatus = .pending
    var canText: Bool = false
    var earlyTerminatorID: String?

    //4. Meta data
    var changeLog: [ChangeLogEntry] = []
    @ServerTimestamp var date_created: Date?
    
    init(draft: EventDraft) {
        self.initiatorId = draft.initiatorId
        self.recipientId = draft.recipientId
        self.type = draft.type
        self.proposedTimes = draft.proposedTimes
        self.location = draft.location ?? EventLocation(mapItem: MKMapItem())
    }
}

extension Event {
    //Firestore field names (used for update/query keys to avoid typos).
    enum Field: String {
        case initiatorId, recipientId, type, proposedTimes, acceptedTime, location, message, status, canText, earlyTerminatorID, changeLog, date_created
    }
}

extension Event.EventType {
    
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
