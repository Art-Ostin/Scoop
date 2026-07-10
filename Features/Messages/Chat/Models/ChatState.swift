//
//  UserEventChatState.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI
import FirebaseFirestore

struct ChatState: Codable {
    
    var unreadCount: Int = 0
    
    var lastMessagePreview: String?
    var lastMessageAuthor: String?
    @ServerTimestamp var lastMessageAt: Date?
    
    enum Field: String {
        case unreadCount, lastMessageAt, lastMessagePreview, lastMessageAuthor
    }
}


