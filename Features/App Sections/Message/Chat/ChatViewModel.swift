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
    
    let defaults: DefaultsManaging
    let session: SessionManager
    let chatRepo: ChatRepository
    let imageLoader: ImageLoading
    let eventProfile: EventProfile
    
    var messages: [MessageModel] = []
    
    init(defaults: DefaultsManaging, session: SessionManager, chatRepo: ChatRepository, imageLoader: ImageLoading, eventProfile: EventProfile, messages: [MessageModel]){
        self.defaults = defaults
        self.session = session
        self.chatRepo = chatRepo
        self.imageLoader = imageLoader
        self.eventProfile = eventProfile
        self.messages = messages
    }

    var userId: String {session.user.id}
    
    func sendMessage(text: String) async throws {
        try await chatRepo.sendMessage(text: text, eventId: eventProfile.id, userId: userId, recipientId: eventProfile.profile.id)
        loadMessages()
    }
    
    func fetchMessages() async throws {
        messages = try await chatRepo.fetchMessages(eventId: eventProfile.id)
    }
    
    func loadImages(profile: EventProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile.profile)
    }
    
    
    func loadMessages()  {
        Task {
            do {
                try await fetchMessages()
            } catch {
                print("No messages Available")
            }
        }
    }

    
    func fetchImages() {
        Task {
            if let loadedMessages = try? await chatRepo.fetchMessages(eventId: eventProfile.event.id) {
                self.messages = loadedMessages
            } else {
                print("No messages Available")
            }
        }
    }
}
