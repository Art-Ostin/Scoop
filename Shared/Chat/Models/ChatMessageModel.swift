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
    
    private static func ago(days: Int = 0, hours: Int = 0, minutes: Int = 0) -> Date {
        let totalSeconds = (days * 24 * 60 * 60) + (hours * 60 * 60) + (minutes * 60)
        return Date(timeIntervalSinceNow: TimeInterval(-totalSeconds))
    }
    
    static let mockChatMessages: [ChatMessageModel] = [
        
        // ~3 days ago
        ChatMessageModel(
            id: "m_001",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Hey—still good for tonight?",
            chatSeen: true,
            dateCreated: Self.ago(days: 3, minutes: 40) // 3d + 40m ago
        ),
        ChatMessageModel(
            id: "m_002",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "No rush btw",
            chatSeen: true,
            dateCreated: Self.ago(days: 3, minutes: 38) // double text
        ),
        
        // ~2 days ago
        ChatMessageModel(
            id: "m_003",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yes! Sorry—was in lab.",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 6) // 2d + 6h ago
        ),
        ChatMessageModel(
            id: "m_004",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "What time were you thinking?",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 5, minutes: 58) // double text
        ),
        ChatMessageModel(
            id: "m_005",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Around 8 works—want something chill near campus?",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 5, minutes: 40)
        ),
        ChatMessageModel(
            id: "m_006",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Chill is perfect. Near campus is ideal.I’m kinda tired lol",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 5, minutes: 30)
        ),
        ChatMessageModel(
            id: "m_007",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Same.I’ll pick something low-key.",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 5, minutes: 22)
        ),
        ChatMessageModel(
            id: "m_008",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Give me 2 mins",
            chatSeen: true,
            dateCreated: Self.ago(days: 2, hours: 5, minutes: 21) // double text
        ),
        
        // ~1 day ago (day-of logistics)
        ChatMessageModel(
            id: "m_009",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Ok: Milky Way (on Parc) or Else’s (closer to campus)?",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 15)
        ),
        ChatMessageModel(
            id: "m_010",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Else’s!",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 12)
        ),
        ChatMessageModel(
            id: "m_011",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "Perfect.Meet outside at 8?",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 10)
        ),
        ChatMessageModel(
            id: "m_012",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Yep 🙂",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 9)
        ),
        ChatMessageModel(
            id: "m_013",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Also I might be like 5 late",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 8) // double text
        ),
        ChatMessageModel(
            id: "m_014",
            chatId: "chat_001",
            authorId: "user_maya",
            content: "Don’t hate me 😭",
            chatSeen: true,
            dateCreated: Self.ago(days: 1, hours: 4, minutes: 7) // triple text
        ),
        
        // ~today (post-date vibe)
        ChatMessageModel(
            id: "m_015",
            chatId: "chat_001",
            authorId: "user_arthur",
            content: "All good 😂Text me when you’re close.",
            chatSeen: true,
            dateCreated: Self.ago(hours: 3, minutes: 12) // 3h 12m ago
        )
    ]
}
