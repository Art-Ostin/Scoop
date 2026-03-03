//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI

struct ChatView: View {
    
    let userId = "user_arthur"
    
    
    @State var lastWasSameUser: Bool = false
    
    let messages = ChatMessageModel.mockChatMessages
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(0..<messages.count, id: \.self) { idx in
                        messageBox(idx: idx)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ChatView()
}

extension ChatView {
    
    @ViewBuilder
    private func messageBox(idx: Int) -> some View {
        let chat = messages[idx]
        let prevIsDifferentUser =
            idx == 0 || messages[idx - 1].authorId != chat.authorId
        let nextIsDifferentUser =
            idx == messages.count - 1 || messages[idx + 1].authorId != chat.authorId
        
        var checkNewDay: Bool {
            if idx == 0 {
                return true
            } else {
                let lastMessage = messages[idx - 1]
                return isNewDay(lastMessage, chat)
            }
        }
        
        let isMyChat = userId == chat.authorId
        
        
        VStack(spacing: 16) {
            
            if checkNewDay {
                if let date = chat.dateCreated {
                    Text(formatDay(day: date))
                        .font(.body(14, .medium))
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background (
                        )
                }
            }
            
            
            ChatMessageView(chat: chat, isMyChat: isMyChat, nextIsDifferentUser: nextIsDifferentUser, lastIsDifferentUser: prevIsDifferentUser)
                .padding(.bottom, nextIsDifferentUser ? 12 : 0)
        }
    }
    
    func formatDay(day: Date) -> String {
        let cal = Calendar.current
        let now = Date()

        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }

        let startDay = cal.startOfDay(for: day)
        let startNow = cal.startOfDay(for: now)
        let diffDays = cal.dateComponents([.day], from: startDay, to: startNow).day ?? 0

        // 2–6 days ago → weekday name
        if (2...6).contains(diffDays) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "EEEE" // Wednesday
            return df.string(from: day).capitalized(with: .current)
        }

        // 7+ days ago (or future) → "Tue 3 Feb"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEE d MMM"
        return df.string(from: day)
    }
    
    func isNewDay(_ lastMessage: ChatMessageModel, _ newMessage: ChatMessageModel) -> Bool {
        if let lastMessageDay = lastMessage.dateCreated, let newMessageDay = newMessage.dateCreated {
            return !Calendar.current.isDate(lastMessageDay, inSameDayAs: newMessageDay)
        }
        return false
    }
}
