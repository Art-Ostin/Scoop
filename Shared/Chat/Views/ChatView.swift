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
    
    @State var lastWasSameUser: Bool = false
    @State var lastWasSameUserIndex: Int = 0
    
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { idx, message in
                        let showTriangle = showTriangle(idx: idx, message: message)
                         
                        ChatMessageView(chat: message, userId: userId, showTriangle: showTriangle, lastWasSameUser: lastWasSameUser)
                            .padding(.bottom, showTriangle ? 8 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func showTriangle(idx: Int, message: ChatMessageModel) -> Bool {
        if message.id != messages.last?.id && idx > 0 { //Not the last or the first message
            let nextMessageAuthor = messages[idx + 1].authorId
            if nextMessageAuthor == message.authorId {
                lastWasSameUserIndex = idx - 1
                lastWasSameUser = true
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

