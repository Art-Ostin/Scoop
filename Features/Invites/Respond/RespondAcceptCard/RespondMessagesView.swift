//
//  RespondMessagesView.swift
//  Scoop
//
//  Created by Art Ostin on 02/04/2026.
//

import SwiftUI

struct RespondMessagesView: View {
    
    let originalMessage: String
    
    let replyMessage: String?
    
    @Binding var showMessageScreen: Bool
    
    var onlyOriginal: Bool {
        replyMessage?.isEmpty != false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            messageBubble(originalMessage, isMyChat: false)
            if let replyMessage {
                Button {
                    showMessageScreen = true
                } label: {
                    messageBubble(replyMessage, isMyChat: true)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.leading, onlyOriginal ? 14 : 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension RespondMessagesView {
    private func messageBubble(_ content: String, isMyChat: Bool) -> some View {
        MessageBubbleView(
            chat: MessageModel(authorId: "", recipientId: "", content: content),
            newAuthor: true,
            nextIsNewAuthor: true, //Change to true for next one
            isMyChat: isMyChat,
            isInviteMessage: true,
            bottomSpacing: 0
        )
        .overlay(alignment: .bottomTrailing) {
            if (replyMessage?.isEmpty != false) {
                Text("Respond")
                    .font(.body(12, .bold))
                    .foregroundStyle(Color.appGreen)
                    .padding(3)
                    .padding(.horizontal, 9)
            }
        }
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
            .padding(.top, 10)
    }
}
/*
 Modifiers I've removed
 
 .overlay(alignment: .leading) {
     messageThreadIndicator
 }
 .padding(.leading, 44)


 
 */

//         .offset(x: onlyOriginal ? 0 : -10)

