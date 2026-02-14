//
//  UserEventModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

import SwiftUI
import FirebaseFirestore


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

