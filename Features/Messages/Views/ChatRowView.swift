//
//  ChatRowView.swift
//  Scoop
//
//  Created by Art Ostin on 26/02/2026.
//

import SwiftUI

struct ChatRowView: View {
    
    let chatPreview: ChatPreview
        
    var body: some View {
        
        HStack(spacing: Spacing.md) {
            profilePhoto
            
            ZStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    nameAndTitle
                    
                    messageAndStatus
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                messageDivider
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 87, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Spacing.md)
    }
}

//Main Sections of ChatRowView
extension ChatRowView {
    
    private var profilePhoto: some View {
        SmallImage(image: chatPreview.image ?? UIImage(), size: 60, isCircle: true)
    }

    private var nameAndTitle: some View {
        HStack(alignment: .top) {
            Text(chatPreview.name)
                .font(.body(18, .bold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            lastMessageTime
        }
    }
    
    private var messageAndStatus: some View {
        HStack(alignment: .top, spacing: Spacing.hairline) {
            messagePreview
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            
            messageStatus
                .fixedSize()
        }
        .padding(.trailing, Spacing.md)
    }
    
    private var messageDivider: some View {
        MapDivider()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}


//Main Elements of ChatRowView
extension ChatRowView {
    
    
    @ViewBuilder
    private var messagePreview: some View {
        if let lastChat = chatPreview.lastChat {
            Text(lastChat)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
        } else {
            Text("Start Chat")
                .font(.body(15, .regular))
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    @ViewBuilder
    private var lastMessageTime: some View {
        let isUnreadMessage = chatPreview.unreadCount > 0
        Text(chatPreview.lastChatTime)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(isUnreadMessage ? Color.textAccent : Color.textSecondary)
            .padding(.trailing, Spacing.md)
    }
    
    @ViewBuilder
    private var messageStatus: some View {
        if chatPreview.unreadCount > 0  {
            Text(String(chatPreview.unreadCount))  //unreadCount
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.white)
                .padding(Spacing.xxs)
                .background (
                    Circle()
                        .fill(.accent)
                )
        }
    }
}
