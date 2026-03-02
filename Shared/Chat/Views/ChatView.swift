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
                LazyVStack {
                    ForEach(messages) {chat in
                        ChatMessageView(chat: chat, userId: userId, showTriangle: true, lastWasSameUser: <#T##Bool#>)
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
    
    
    private func showTriangle(idx: Int, message: ChatMessageModel) {
        let isFirst: Bool = (messages.first?.id).map { $0 == message.id } ?? false
        let isLast: Bool = (messages.last?.id).map { $0 == message.id } ?? false
        
        if !isLast {
            let nextMessage = messages[idx + 1]
            
            
        }
    }
}
