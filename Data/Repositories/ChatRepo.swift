//
//  MessageRepo.swift
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
    
    func sendMessage(text: String, eventId: String, userId: String, recipientId: String) async throws {
        //1. Create the textMessage Model and add it to the right document
        let textMessage = MessageModel(authorId: userId, recipientId: recipientId, content: text)
        _ = try fs.add(chatMessagePath(eventId: eventId), value: textMessage)
        
        //2. Update the chatDocuments to reflect most recent
        let fields: [String : Any ] = [ChatModel.Field.lastMessageAt.rawValue : FieldValue.serverTimestamp()]
        async let updateThread: Void = fs.update(chatThreadPath(eventId: eventId), fields: fields)
        async let updateRecentChat: Void = eventsRepo.updateRecentChat(message: textMessage, eventId: eventId)
        _ = try await (updateThread, updateRecentChat)
    }
    
    func fetchMessages(eventId: String) async throws -> [MessageModel] {
        let path = chatMessagePath(eventId: eventId)
        let messages: [MessageModel] = try await fs.fetchFromCollection(path) { query in
            query
                .order(by: MessageModel.Field.dateCreated.rawValue, descending: true)
                .limit(to: 100)
        }
        return Array(messages.reversed())
    }
    
    //To track any updates to the chat folder
    func chatsTracker(userId: String) -> AsyncThrowingStream<FSCollectionEvent<ChatModel>, Error>  {
        let path = "chats"
        return fs.streamCollection(path) { query in
            query.whereField(ChatModel.Field.participantIds.rawValue, arrayContains: userId)
        }
    }
}
    
