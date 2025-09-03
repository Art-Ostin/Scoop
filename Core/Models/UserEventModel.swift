//
//  EdgeEvents.swift
//  ScoopTest
//
//  Created by Art Ostin on 12/08/2025.
//

import Foundation
import FirebaseFirestore

enum EdgeRole: String, Codable { case sent, received }

struct UserEvent: Identifiable, Codable {
    
    @DocumentID var id: String?
    let otherUserId: String
    let role: EdgeRole
    let status: EventStatus
    let time: Date
    let type: String
    let message: String?
    let place: EventLocation
    let otherUserName: String
    let otherUserPhoto: String
    let updatedAt: Date?
    let inviteExpiryTime: Date
    var canMessage: Bool = false
    
    enum Field: String, Codable {
        case id, otherUserId, role, status, time, type, message, place, otherUserName, otherUserPhoto, updatedAt, invite_expiry_time, canMessage
    }
}



