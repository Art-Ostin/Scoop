//
//  UserEventChatState.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct UserEventChatState: Codable {
    var unreadCount: Int = 0
    var lastMessageAt: Date?
    var lastMessagePreview: String?
    var lastMessageAuthor: String?
    
    
    
    enum Field: String {
        case unreadCount, lastMessageAt, lastMessagePreview, lastMessageAuthor
    }
}

//When constructing the message
struct ChatDraftMessage {
    let text: String
    let authorId: String
    let recipientId: String
    let eventId: String
}

//For Pagination
struct ChatMessageCursor {
    let lastMessageId: String
}
