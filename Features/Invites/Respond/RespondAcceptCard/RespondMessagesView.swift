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
    
    var body: some View {
        HStack {
            VStack {
                MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: originalMessage), newAuthor: true, nextIsNewAuthor: true, isMyChat: false, isInviteMessage: true)
                
                MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: replyMessage), newAuthor: true, nextIsNewAuthor: true, isMyChat: true, isInviteMessage: true)
            }
        }
    }
}
