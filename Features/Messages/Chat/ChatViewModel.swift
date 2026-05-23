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

    static let messageAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.86)

    let defaults: DefaultsManaging
    let session: SessionManager
    let chatRepo: ChatRepository
    let imageLoader: ImageLoading
    let eventProfile: EventProfile

    var messages: [MessageModel] = []
    private var pendingTempIds: Set<String> = []

    init(defaults: DefaultsManaging, session: SessionManager, chatRepo: ChatRepository, imageLoader: ImageLoading, eventProfile: EventProfile) {
        self.defaults = defaults
        self.session = session
        self.chatRepo = chatRepo
        self.imageLoader = imageLoader
        self.eventProfile = eventProfile
    }

    var userId: String {session.user.id}

    func isMyChat(_ message: MessageModel) -> Bool {
        message.authorId == userId
    }

    func isNewAuthor(for message: MessageModel) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }), idx > 0 else { return true }
        return messages[idx - 1].authorId != message.authorId
    }

    func isNextNewAuthor(for message: MessageModel) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        return idx == messages.count - 1 || messages[idx + 1].authorId != message.authorId
    }

    func isNewDay(for message: MessageModel) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        guard idx > 0 else { return true }
        guard let lastDay = messages[idx - 1].dateCreated, let newDay = message.dateCreated else { return false }
        return !Calendar.current.isDate(lastDay, inSameDayAs: newDay)
    }

    func sendMessage(text: String) async throws {
        var optimistic = MessageModel(authorId: userId, recipientId: eventProfile.profile.id, content: text)
        let tempId = "temp-\(UUID().uuidString)"
        optimistic.id = tempId
        optimistic.dateCreated = Date()
        pendingTempIds.insert(tempId)
        withAnimation(Self.messageAnimation) {
            self.messages.append(optimistic)
        }
        do {
            try await chatRepo.sendMessage(text: text, eventId: eventProfile.id, userId: userId, recipientId: eventProfile.profile.id)
        } catch {
            pendingTempIds.remove(tempId)
            withAnimation(Self.messageAnimation) {
                self.messages.removeAll { $0.id == tempId }
            }
            throw error
        }
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
                    // Reconcile with optimistic temp if present (same author + content).
                    if let tempIdx = self.messages.firstIndex(where: { msg in
                        guard let id = msg.id, self.pendingTempIds.contains(id) else { return false }
                        return msg.authorId == message.authorId && msg.content == message.content
                    }) {
                        if let tempId = self.messages[tempIdx].id {
                            self.pendingTempIds.remove(tempId)
                        }
                        self.messages[tempIdx] = message
                    } else {
                        withAnimation(Self.messageAnimation) {
                            self.messages.append(message)
                        }
                    }
                case .modified(let message):
                    if let idx = self.messages.firstIndex(where: { $0.id == message.id }) {
                        self.messages[idx] = message
                    }
                case .removed(let id):
                    withAnimation(Self.messageAnimation) {
                        self.messages.removeAll { $0.id == id }
                    }
                }
            }
        } catch {
            print("Messages stream error: \(error)")
        }
    }
}
