//
//  ChatMessageModel.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.


import Foundation
import FirebaseFirestore

struct ChatMessageModel: Identifiable, Hashable {
    let id: String
    let chatId: String
    let authorId: String
    let content: String
    let chatSeen: Bool
    @ServerTimestamp var dateCreated: Date?

    static let mockChatMessages: [ChatMessageModel] = [
        // 3 days ago
        ChatMessageModel(
            id: "m_001",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Hey—still good?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 + 60 * 12)
        ),
        ChatMessageModel(
            id: "m_002",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "No rush btw—just checking.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 + 60 * 14)
        ),
        ChatMessageModel(
            id: "m_003",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yes! Sorry—was in back-to-back labs 😭",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 + 60 * 40)
        ),
        ChatMessageModel(
            id: "m_004",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "What time were you thinking?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 3 + 60 * 42)
        ),
        
        // 2 days ago
        ChatMessageModel(
            id: "m_005",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "All good. Around 8?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 5)
        ),
        ChatMessageModel(
            id: "m_006",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "I was thinking something chill near campus.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 7)
        ),
        ChatMessageModel(
            id: "m_007",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Chill is perfect. Any spot in mind?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 20)
        ),
        ChatMessageModel(
            id: "m_008",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Yeah—I'll send one.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 28)
        ),
        ChatMessageModel(
            id: "m_009",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Dieu du Ciel? Or somewhere quieter?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 30)
        ),
        ChatMessageModel(
            id: "m_010",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Open to whatever you prefer.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 31)
        ),
        ChatMessageModel(
            id: "m_011",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Quieter might be nicer to actually talk 🙂",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 45)
        ),
        ChatMessageModel(
            id: "m_012",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Also—food or just drinks?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 * 2 + 60 * 47)
        ),
        
        // yesterday
        ChatMessageModel(
            id: "m_013",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Just drinks to start. If it goes well, we can grab a bite after.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 + 60 * 10)
        ),
        ChatMessageModel(
            id: "m_014",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Perfect. Send the location?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 24 + 60 * 22)
        ),
        
        // today (most recent)
        ChatMessageModel(
            id: "m_015",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Cool—let’s do Bar George?",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 2 - 20 * 60)
        ),
        ChatMessageModel(
            id: "m_016",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Or I can pick something closer to McGill if that’s easier.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 2 - 18 * 60)
        ),
        ChatMessageModel(
            id: "m_017",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "McGill area pls 🙏",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 2 - 5 * 60)
        ),
        ChatMessageModel(
            id: "m_018",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "And yes 8 still works!",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 2 - 4 * 60)
        ),
        ChatMessageModel(
            id: "m_019",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Done. Let’s do Gertie’s — super close.",
            chatSeen: true,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 1 - 55 * 60)
        ),
        ChatMessageModel(
            id: "m_020",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Meet outside at 8?",
            chatSeen: false,
            dateCreated: Date(timeIntervalSinceNow: -60 * 60 * 1 - 50 * 60)
        )
    ]
}
