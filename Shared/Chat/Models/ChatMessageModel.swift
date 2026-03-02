//
//  ChatMessageModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.


import Foundation

struct ChatMessageModel: Identifiable, Hashable {
    let id: String
    let chatId: String
    let authorId: String
    let content: String
    let chatSeen: Bool
    let dateCreated: Date?
    
    static let mockChatMessages: [ChatMessageModel] = [
        ChatMessageModel(
            id: "m_001",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Hey—still good?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24)
        ),
        ChatMessageModel(
            id: "m_002",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yep! What time were you thinking?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23 - 50 * 60)
        ),
        ChatMessageModel(
            id: "m_003",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Around 8 works—want something chill?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23 - 40 * 60)
        ),
        ChatMessageModel(
            id: "m_004",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Chill is perfect. Near campus?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23 - 30 * 60)
        ),
        ChatMessageModel(
            id: "m_005",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Yep—I'll send a spot in a sec.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23 - 20 * 60)
        ),
        ChatMessageModel(
            id: "m_006",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Nice. Also—are we doing food or just drinks?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23 - 10 * 60)
        ),
        ChatMessageModel(
            id: "m_007",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Just drinks to start. If it goes well, we can grab a bite after.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 23)
        ),
        ChatMessageModel(
            id: "m_008",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Sounds good 🙂",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 22 - 50 * 60)
        ),
        ChatMessageModel(
            id: "m_009",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Cool—meet outside at 8?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 22 - 40 * 60)
        ),
        ChatMessageModel(
            id: "m_010",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yep. See you then!",
            chatSeen: false,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 22 - 30 * 60)
        )
    ]
}

