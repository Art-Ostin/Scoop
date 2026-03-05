//
//  ChatMessageModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.


import Foundation
import FirebaseFirestore

struct MessageModel: Identifiable, Hashable, Codable {
    
    //So always ID even if not saved yet
    @DocumentID var _id: String?
    var localId: String = UUID().uuidString
    var id: String { _id ?? localId }
    
    
    let authorId: String
    let recipientId: String
    let content: String
    @ServerTimestamp var dateCreated: Date?
    
    var readByRecipient = false
    
    init(authorId: String, recipientId: String, content: String) {
        self.authorId = authorId
        self.recipientId = recipientId
        self.content = content
    }
    
    enum Field: String {
        case authorId, recipientId, content, dateCreated
    }
}
