//
//  ChatMessageModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.


import Foundation
import FirebaseFirestore

struct ChatMessageModel: Identifiable, Hashable, Codable {
    
    //So always ID even if not saved yet
    @DocumentID var _id: String?
    var localId: String = UUID().uuidString
    var id: String { _id ?? localId }
    
    let authorId: String
    let recipientId: String
    let content: String
    @ServerTimestamp var createdAt: Date?
    
    var readByRecipient: Bool = false
    
    init(draftMessage: ChatDraftMessage) {
        authorId = draftMessage.authorId
        recipientId = draftMessage.recipientId
        content = draftMessage.text
    }
}
