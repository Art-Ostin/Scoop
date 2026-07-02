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
        
        HStack(spacing: 16) {
            profilePhoto
            
            ZStack {
                VStack(alignment: .leading, spacing: 4) {
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
        .padding(.leading, 16)
    }
}

//Main Sections of ChatRowView
extension ChatRowView {
    
    private var profilePhoto: some View {
        Image(uiImage: chatPreview.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
    }

    private var nameAndTitle: some View {
        HStack(alignment: .top) {
            Text(chatPreview.name)
                .font(.body(18, .bold))
                .foregroundStyle(Color.black)
            Spacer()
            lastMessageTime
        }
    }
    
    private var messageAndStatus: some View {
        HStack(alignment: .top, spacing: 2) {
            messagePreview
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            
            messageStatus
                .fixedSize()
        }
        .padding(.trailing, 16)
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
                .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.42))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
        } else {
            Text("Start Chat")
                .font(.body(15, .regular))
                .foregroundStyle(Color.grayText)
        }
    }
    
    @ViewBuilder
    private var lastMessageTime: some View {
        let isUnreadMessage = chatPreview.unreadCount > 0
        Text(chatPreview.lastChatTime)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(isUnreadMessage ? Color.accent : Color(red: 0.42, green: 0.42, blue: 0.42))
            .padding(.trailing, 16)
    }
    
    @ViewBuilder
    private var messageStatus: some View {
        if chatPreview.unreadCount > 0  {
            Text(String(chatPreview.unreadCount))  //unreadCount
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.white)
                .padding(5)
                .background (
                    Circle()
                        .fill(.accent)
                )
        }
    }
}
