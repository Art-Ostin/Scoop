//
//  ChatRepo.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import Foundation
import FirebaseFirestore

class ChatRepo: ChatRepository {
    
    private let eventsRepo: EventsRepository
    
    private let fs: FirestoreService
    
    init(eventsRepo: EventsRepository, fs: FirestoreService) {
        self.eventsRepo = eventsRepo
        self.fs = fs
    }
    
    private func chatThreadPath(eventId: String) -> String {
        return "chats/\(eventId)"
    }
    
    private func chatMessagePath(eventId: String) -> String {
        return "chats/\(eventId)/messages"
    }
    
    func newMessageId(eventId: String) -> String {
        fs.newDocumentId(in: chatMessagePath(eventId: eventId))
    }

    func sendMessage(id: String, text: String, eventId: String, userId: String, recipientId: String) async throws {
        //1. Create the textMessage Model and set it at the id the sender already shows. Built here with a
        //nil date: @ServerTimestamp only writes the server sentinel for nil, and the `.modified` echo that
        //stamps the row depends on it.
        let textMessage = ChatMessage(authorId: userId, recipientId: recipientId, content: text)
        try fs.set("\(chatMessagePath(eventId: eventId))/\(id)", value: textMessage)
        
        //2. Update the chatDocuments to reflect most recent
        let fields: [String : Any ] = [ChatThread.Field.lastMessageAt.rawValue : FieldValue.serverTimestamp()]
        async let updateThread: Void = fs.update(chatThreadPath(eventId: eventId), fields: fields)
        async let updateRecentChat: Void = eventsRepo.updateRecentChat(message: textMessage, eventId: eventId)
        _ = try await (updateThread, updateRecentChat)
    }
    
    func fetchMessages(eventId: String) async throws -> [ChatMessage] {
        let path = chatMessagePath(eventId: eventId)
        let messages: [ChatMessage] = try await fs.fetchFromCollection(path) { query in
            query
                .order(by: ChatMessage.Field.dateCreated.rawValue, descending: true)
                .limit(to: 100)
        }
        return Array(messages.reversed())
    }
    
    //To track any updates to the user's chat folder
    func chatsTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatThread>, Error>  {
        let path = "chats"
        return fs.streamCollection(path) { query in
            query.whereField(ChatThread.Field.participantIds.rawValue, arrayContains: userId)
        }
    }
    
    //To track any updates to a message (when opened)
    func messagesTracker(eventId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatMessage>, Error> {
        let path = chatMessagePath(eventId: eventId)
        return fs.streamCollection(path) { query in
            query
                .order(by: ChatMessage.Field.dateCreated.rawValue, descending: true)
                .limit(to: 100)
        }
    }
}
    
