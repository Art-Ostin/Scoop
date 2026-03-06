//
//  ChatModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import Foundation
import FirebaseFirestore


struct ChatModel: Codable {
    let participantIds: [String]
    
    var lastMessageAt: Date?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    enum Field: String {
        case participantsIds, lastMessageAt, createdAt, updatedAt
    }
}
