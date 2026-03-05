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
        let textMessage = MessageModel(authorId: userId, recipientId: recipientId, content: text)
        
        let chatThread = ChatThread(id: eventId, participantIds: [userId, recipientId])
        
        //Adds the specific message
        try fs.set(chatThreadPath(eventId: eventId), value: chatThread, merge: true)
        _ = try fs.add(chatThreadPath(eventId: eventId), value: textMessage)
        
        try await eventsRepo.updateRecentChat(message: textMessage, eventId: eventId)
    }
    
    
    
    
    
    func fetchMessages(eventId: String) async throws -> [MessageModel] {
        let path = chatMessagePath(eventId: eventId)
        let messages: [MessageModel] = try await fs.fetchFromCollection(path, orderBy: FSOrder(field: MessageModel.Field.dateCreated.rawValue, descending: true), limit: 100)
        return messages
    }
            
    //Set up streaming Messages
    
    
    /*
     
     
     let isFirstChat = try await fs.exists(chatThreadPath(eventId: eventId))
     print(isFirstChat)
     
     if isFirstChat {
         let chatThread = ChatThread(eventId: eventId, participantIds: [userId, recipientId], lastMessagePreview: String(text.prefix(50)), lastMessageAuthorId: userId, lastMessageAt: Date(), createdAt: Date(), updatedAt: Date())
         
         print("Reached here")
         try fs.set(chatThreadPath(eventId: eventId), value: chatThread)
         print("And got past this hurdle")
     }
     print("Before Bug")
     _ = try fs.add(chatMessagePath(eventId: eventId), value: textMessage)
     print("Completed this")
     
     
     */
    
    
    
    
    
    
    
    ///Firebase Architecture
    //One Path to store all the Chats in simply an ID (On same level as 'events' and users)
    
    //The Chat IDs are the same as the eventIDs so to retrieve the correct chat from this collection query using the eventID
    
    //Inside each chat ID have the ChatModel Then as subcollection of the messages, (I.e. in this subcollection a long list of ID strings and within each one is the message info (content, author, id)
    
    
    
}


/*
 
 
 //Create the document first (merging if not there).
 
 
//       let snap = try await chatMessagePath(eventId: eventId).getDocument()
 
 //If no document with the eventID inside the 'chats' collection, create a document inputting the ChatThread
 
 //After that, set the textMessage inside the subcollection of that document 'messages' (i.e. putting messages in there)
 
 try fs.set(chatThreadPath(eventId: eventId), value: textMessage)
 */
