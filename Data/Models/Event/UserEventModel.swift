//
//  UserEventModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

import SwiftUI
import FirebaseFirestore

//Event stored in user's profile with all Info they require about event (Check if not better to just store reference to event instead)
struct UserEvent: Identifiable, Codable {
    
    enum EdgeRole: String, Codable {
        case sent, received
    }

    //1. Event Identifier and trick to get non-optional id
    @DocumentID var _id: String?
    var id: String {
        guard let _id else {
            preconditionFailure("UserEvent ID accessed before Firestore assigned a document ID.")
        }
        return _id
    }
    
    //2.Other userInfo & Role
    let otherUserId: String
    let otherUserName: String
    let otherUserPhoto: String
    let role: EdgeRole
    
    //3. Event Information
    var type: Event.EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var message: String?
    
    //4. Event Updatable Information
    var status: Event.EventStatus = .pending
    var canText: Bool = false
    var chatState: ChatState?

    //5. MetaData
    var updatedAt: Date? = nil
    var earlyTerminatorID: String? = nil
    
    init(otherProfile: UserProfile, role: EdgeRole, event: Event) {
        otherUserId = otherProfile.id
        otherUserName = otherProfile.name
        otherUserPhoto = otherProfile.imagePathURL.first ?? ""
        self.role = role
        
        type = event.type
        proposedTimes = event.proposedTimes
        acceptedTime = event.acceptedTime
        location = event.location
        message = event.message
    }
}

extension UserEvent {
    //Firestore field names (used for update/query keys to avoid typos).
    enum Field: String {
        case otherUserId, otherUserName, otherUserPhoto, role,
             type, proposedTimes, acceptedTime, location, message,
             status, canText, updatedAt, earlyTerminatorID, chatState
    }
}
