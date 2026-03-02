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
        
        // ~3 days ago
        ChatMessageModel(
            id: "m_001",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Hey—still good for tonight?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 - 40 * 60) // 3d + 40m ago
        ),
        ChatMessageModel(
            id: "m_002",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "No rush btw",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 - 38 * 60) // double text
        ),
        
        // ~2 days ago
        ChatMessageModel(
            id: "m_003",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yes! Sorry—was in lab.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 6 * 60 * 60) // 2d + 6h ago
        ),
        ChatMessageModel(
            id: "m_004",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "What time were you thinking?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 5 * 60 * 60 - 58 * 60) // double text
        ),
        ChatMessageModel(
            id: "m_005",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Around 8 works—want something chill near campus?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 5 * 60 * 60 - 40 * 60)
        ),
        ChatMessageModel(
            id: "m_006",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Chill is perfect.\nNear campus is ideal.\nI’m kinda tired lol",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 5 * 60 * 60 - 30 * 60)
        ),
        ChatMessageModel(
            id: "m_007",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Same.\nI’ll pick something low-key.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 5 * 60 * 60 - 22 * 60)
        ),
        ChatMessageModel(
            id: "m_008",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Give me 2 mins",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 - 5 * 60 * 60 - 21 * 60) // double text
        ),
        
        // ~1 day ago (day-of logistics)
        ChatMessageModel(
            id: "m_009",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Ok: Milky Way (on Parc) or Else’s (closer to campus)?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 15 * 60)
        ),
        ChatMessageModel(
            id: "m_010",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Else’s!",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 12 * 60)
        ),
        ChatMessageModel(
            id: "m_011",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Perfect.\nMeet outside at 8?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 10 * 60)
        ),
        ChatMessageModel(
            id: "m_012",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yep 🙂",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 9 * 60)
        ),
        ChatMessageModel(
            id: "m_013",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Also I might be like 5 late",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 8 * 60) // double text
        ),
        ChatMessageModel(
            id: "m_014",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Don’t hate me 😭",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 - 4 * 60 * 60 - 7 * 60) // triple text
        ),
        
        // ~today (post-date vibe)
        ChatMessageModel(
            id: "m_015",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "All good 😂\nText me when you’re close.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 3 - 12 * 60) // 3h 12m ago
        )
    ]

}

