//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI

struct ChatView: View {
    
    let userId = "user_arthur"
    
    
    let messages = ChatMessageModel.mockChatMessages
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { idx, message in
                        let showTriangle = showTriangle(idx: idx, message: message)
                        ChatMessageView(chat: message, userId: userId, showTriangle: showTriangle)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func showTriangle(idx: Int, message: ChatMessageModel) -> Bool {
        if message.id != messages.last?.id && idx > 1 { //Not the last or the first message
            let lastMessageAuthor = messages[idx - 1].authorId
            let nextMessageAuthor = messages[idx + 1].authorId
            if lastMessageAuthor != message.authorId && nextMessageAuthor == message.authorId {
                return false
            }
        }
        return true
    }
}

#Preview {
    ChatView()
}

extension ChatView {
    
    private var typeMessageView: some View {
        
        Text("Hello")
    }
}

