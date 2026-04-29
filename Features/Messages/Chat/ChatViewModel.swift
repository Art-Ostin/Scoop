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
    
    init(defaults: DefaultsManaging, session: SessionManager, chatRepo: ChatRepository, imageLoader: ImageLoading, eventProfile: EventProfile) {
        self.defaults = defaults
        self.session = session
        self.chatRepo = chatRepo
        self.imageLoader = imageLoader
        self.eventProfile = eventProfile
    }

    var userId: String {session.user.id}
    
    func sendMessage(text: String) async throws {
        try await chatRepo.sendMessage(text: text, eventId: eventProfile.id, userId: userId, recipientId: eventProfile.profile.id)
    }
    
    
    func loadImages(profile: EventProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile.profile)
    }
    

    
    func startListening() async {
        do {
            for try await change in chatRepo.messagesTracker(eventId: eventProfile.id) {
                switch change {
                case .initial(let initial):
                    self.messages = initial.reversed()
                case .added(let message):
                    self.messages.append(message)
                case .modified(let message):
                    if let idx = self.messages.firstIndex(where: { $0.id == message.id }) {
                        self.messages[idx] = message
                    }
                case .removed(let id):
                    self.messages.removeAll { $0.id == id }
                }
            }
        } catch {
            print("Messages stream error: \(error)")
        }
    }
}
