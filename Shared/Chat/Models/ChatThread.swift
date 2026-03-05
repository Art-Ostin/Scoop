//
//  ChatModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import Foundation
import FirebaseFirestore


struct ChatThread: Codable {
    var id: String
    let participantIds: [String]
    
    var lastMessageAt: Date?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
