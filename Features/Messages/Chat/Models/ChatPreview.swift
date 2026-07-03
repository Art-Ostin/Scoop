//
//  ChatPreview.swift
//  Scoop
//
//  Created by Art Ostin on 18/05/2026.
//

import SwiftUI

struct ChatPreview: Hashable {
    let image: UIImage?
    let name: String
    let lastChat: String?
    let unreadCount: Int
    let lastChatTime: String
    
    init(eventProfile: EventProfile) {
        let chatState = eventProfile.chatState
        
        self.image = eventProfile.image
        self.name = eventProfile.profile.name
        self.lastChat = chatState?.lastMessagePreview ?? ""
        self.unreadCount = chatState?.unreadCount ?? 0
        self.lastChatTime = FormatEvent.messageTime(chatState?.lastMessageAt ?? Date())
    }
}
