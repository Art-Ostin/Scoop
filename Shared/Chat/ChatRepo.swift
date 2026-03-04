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
    
    internal func sendMessage(draftMessage: ChatDraftMessage, event: UserEvent) async throws {
        //Set it in the Event
        let chatMessage = ChatMessageModel(draftMessage: draftMessage)
        try fs.set(chatMessagePath(eventId: draftMessage.eventId), value: chatMessage)
        
        //Set it in the userEvents
        let authorId = chatMessage.authorId
        let recipientId = chatMessage.recipientId
        guard let userEventId = event.id else {return}
        let message = chatMessage.content
        
        try await eventsRepo.updateUserEventChatState(userEventId: userEventId, userId: authorId, message: chatMessage, isRecipient: false)
        try await eventsRepo.updateUserEventChatState(userEventId: userEventId, userId: recipientId, message: chatMessage, isRecipient: true)
    }
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    ///Firebase Architecture
    //One Path to store all the Chats in simply an ID (On same level as 'events' and users)
    
    //The Chat IDs are the same as the eventIDs so to retrieve the correct chat from this collection query using the eventID
    
    //Inside each chat ID have the ChatModel Then as subcollection of the messages, (I.e. in this subcollection a long list of ID strings and within each one is the message info (content, author, id)
    
    
    
}
