//
//  ChatModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import Foundation
import FirebaseFirestore


struct ChatThread: Codable, Identifiable {
    let eventId: String
    var id: String { eventId }
    let participantIds: [String]
    
    var lastMessagePreview: String?
    var lastMessageAuthorId: String?
    var lastMessageAt: Date?

    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

}
