//
//  MessageRepo.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import Foundation

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
        //Set the textMessage
        let textMessage = ChatMessageModel(authorId: userId, recipientId: recipientId, content: text)
        try fs.set(chatMessagePath(eventId: eventId), value: textMessage)
        
        try await eventsRepo.updateRecentChat(eventId: eventId , userId: userId, message: textMessage, isRecipient: false)
        try await eventsRepo.updateRecentChat(eventId: eventId , userId: recipientId, message: textMessage, isRecipient: true)
    }
    
    func fetchMessages(eventId: String) async throws -> [ChatMessageModel] {
        let path = chatMessagePath(eventId: eventId)
        let messages: [ChatMessageModel] = try await fs.fetchFromCollection(path, orderBy: FSOrder(field: ChatMessageModel.Field.createdAt.rawValue, descending: true), limit: 100)
        return messages
    }
    
    //Set up streaming Messages 
    
    
    
    
    
    
    
    
    
    ///Firebase Architecture
    //One Path to store all the Chats in simply an ID (On same level as 'events' and users)
    
    //The Chat IDs are the same as the eventIDs so to retrieve the correct chat from this collection query using the eventID
    
    //Inside each chat ID have the ChatModel Then as subcollection of the messages, (I.e. in this subcollection a long list of ID strings and within each one is the message info (content, author, id)
    
    
    
}

