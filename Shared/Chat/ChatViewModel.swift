//
//  ConversationsViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    
    let session: SessionManager
    let chatRepo: ChatRepository
    
    let profileModel: ProfileModel
    
    let messages: [ChatMessageModel] = []
    
    init(session: SessionManager, chatRepo: ChatRepository, profileModel: ProfileModel) {
        self.chatRepo = chatRepo
        self.session = session
        self.profileModel = profileModel
    }
        
    
    var userId: String {session.user.id}
    
    
    func sendMessage(text: String) async throws {
        guard let eventId = profileModel.event?.id else {return}
        let recipientId = profileModel.profile.id
        try await chatRepo.sendMessage(text: text, eventId: eventId, userId: userId, recipientId: recipientId)
    }
}
