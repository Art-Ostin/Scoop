//
//  RespondMessagesView.swift
//  Scoop
//
//  Created by Art Ostin on 02/04/2026.
//

import SwiftUI

struct RespondMessagesView: View {
    
    let showTimePopup: Bool
    let originalMessage: String
    
    let replyMessage: String
    
    @Binding var showMessageScreen: Bool
    
    private let rowSpacing: CGFloat = 12
    private let bubbleSpacing: CGFloat = 18


    var body: some View {
        VStack(spacing: bubbleSpacing - 12) {
            
            MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: originalMessage), newAuthor: true, nextIsNewAuthor: true, isMyChat: false, isInviteMessage: true, bottomSpacing: 0)

            MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: replyMessage), newAuthor: true, nextIsNewAuthor: true, isMyChat: true, isInviteMessage: true, bottomSpacing: 0)
                .onTapGesture {
                    showMessageScreen = true
                }
        }
        .offset(x: -10)
        .padding(.vertical, 6)
        .padding(.leading, 44)
        .padding(.trailing, 6)
        .padding(.bottom, 4)
        .overlay(alignment: .leading) {
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
    
    private var lineProgression: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.accent.opacity(showTimePopup ? 0.04 : 0.2),
                        Color.accent.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
            .padding(.vertical, 10)
    }
}
