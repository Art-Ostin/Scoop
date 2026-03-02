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
                        let chat = messages[idx]
                        let prevIsDifferentUser =
                            idx == 0 || messages[idx - 1].authorId != chat.authorId

                        let nextIsDifferentUser =
                            idx == messages.count - 1 || messages[idx + 1].authorId != chat.authorId

                        
                        let isMyChat = userId == chat.authorId
                        
                        
                        ChatMessageView(chat: chat, isMyChat: isMyChat, nextIsDifferentUser: nextIsDifferentUser, lastIsDifferentUser: prevIsDifferentUser)
                            .padding(.bottom, nextIsDifferentUser ? 12 : 0)
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

        
        let isMyChat = userId == chat.authorId
    
        let startsNewDay: Bool =
            idx == 0 ||
            {
                guard
                    let cur = messages[idx].dateCreated,
                    let prev = messages[idx - 1].dateCreated
                else { return false }   // or `true` if you want nil dates to force a "new day"
                
                return !Calendar.current.isDate(cur, inSameDayAs: prev)
            }()
        
        VStack {
            if startsNewDay {
                
                
            } else {
                
            }
            
            ChatMessageView(chat: chat, isMyChat: isMyChat, nextIsDifferentUser: nextIsDifferentUser, lastIsDifferentUser: prevIsDifferentUser)
                .padding(.bottom, nextIsDifferentUser ? 12 : 0)
        }
    }
    
}
