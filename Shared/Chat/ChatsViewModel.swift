//
//  ConversationsViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI


@Observable
class ChatsViewModel {
    
    let chatRepo: ChatRepository
    
    let eventId: String
    
    init(chatRepo: ChatRepository, eventId: String) {
        self.chatRepo = chatRepo
        self.eventId = eventId
    }
    
    let messages: [ChatMessageModel] = [ ]
    
    
}
