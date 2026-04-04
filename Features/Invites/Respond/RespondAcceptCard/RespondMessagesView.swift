//
//  RespondMessagesView.swift
//  Scoop
//
//  Created by Art Ostin on 02/04/2026.
//

import SwiftUI

struct RespondMessagesView: View {
    
    let originalMessage: String
    let replyMessage: String
    
    @Binding var showMessageScreen: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            messageBubble(originalMessage, isMyChat: false)

            Button {
                showMessageScreen = true
            } label: {
                messageBubble(replyMessage, isMyChat: true)
            }
            .buttonStyle(.plain)
        }
        .offset(x: -10)
        .padding(.vertical, 6)
        .padding(.leading, 44)
        .padding(.trailing, 6)
        .padding(.bottom, 4)
        .overlay(alignment: .leading) {
            messageThreadIndicator
        }
    }
}

extension RespondMessagesView {
    private func messageBubble(_ content: String, isMyChat: Bool) -> some View {
        MessageBubbleView(
            chat: MessageModel(authorId: "", recipientId: "", content: content),
            newAuthor: true,
            nextIsNewAuthor: true,
            isMyChat: isMyChat,
            isInviteMessage: true,
            bottomSpacing: 0
        )
    }

    private var messageThreadIndicator: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.accent.opacity(0.2),
                        Color.accent.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
            .padding(.leading, 5)
            .padding(.top, 6)
    }
}
