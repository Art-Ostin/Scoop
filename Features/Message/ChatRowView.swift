//
//  ChatRowView.swift
//  Scoop
//
//  Created by Art Ostin on 26/02/2026.
//

import SwiftUI

struct ChatRowView: View {
    
    let image: UIImage
    let event: UserEvent
    
    var body: some View {
        HStack(spacing: 24) {
            
            profilePhoto
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.otherUserName)
                    .font(.body(20, .bold))
                
                messagePreview
            }
        }
        .frame(height: 90, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension ChatRowView {
    
    private var profilePhoto: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 65, height: 65)
            .clipShape(Circle())
    }
    
    @ViewBuilder
    private var messagePreview: some View {
        if let chat = event.recentChatState {
            let unread = chat.unreadCount > 0
            Text(chat.lastMessagePreview ?? "")
                .font(.body(15, unread ? .bold : .regular))
                .foregroundStyle(unread ? .black : .grayText)
                .lineSpacing(6)
                .lineLimit(1)
        } else {
            Text("Start Chat")
                .font(.body(15, .regular))
                .foregroundStyle(Color.grayText)
        }
    }
}
