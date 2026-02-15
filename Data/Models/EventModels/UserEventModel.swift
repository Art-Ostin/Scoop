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

    //1. Event Identifier
    @DocumentID var id: String?
    
    //2.Other userInfo & Role
    let otherUserId: String
    let otherUserName: String
    let otherUserPhoto: String
    let role: Event.EdgeRole
    
    //3. Event Information
    var type: Event.EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var message: String?
    
    //4. Event Updatable Information
    var status: Event.EventStatus
    var canText: Bool = false

    //5. MetaData
    let updatedAt: Date?
    var earlyTerminatorID: String?
}

extension UserEvent {
    //Firestore field names (used for update/query keys to avoid typos).
    enum Field: String {
        case otherUserId, otherUserName, otherUserPhoto, role,
             type, proposedTimes, acceptedTime, location, message,
             status, canText, updatedAt, earlyTerminatorID
    }
}
