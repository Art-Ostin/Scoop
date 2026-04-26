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
    
    var lastMessageAt: String {
        if let lastMessageTime = event.chatState?.lastMessageAt {
            return FormatEvent.hourTime(lastMessageTime)
        } else {
            return ""
        }
    }
    
    var unreadCount: Int {
        event.chatState?.unreadCount ?? 0
    }
    
    var isUnreadMessage: Bool {
        return unreadCount >= 1
    }
    
    var body: some View {
        
        HStack(spacing: 16) {
            profilePhoto
            
            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    
                    HStack(alignment: .top) {
                        Text(event.otherUserName)
                            .font(.body(18, .bold))
                        Spacer()
                        lastMessageTime
                    }
                    
                    HStack(alignment: .top, spacing: 2) {
                        messagePreview
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                        
                        messageStatus
                            .fixedSize()
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MapDivider()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 87, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
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
        if let chat = event.chatState {
//            let unread = chat.unreadCount > 0
            Text("This is an example of seeing how the") //maessage looks when you flip it around to have two screens
                .font(.system(size: 15, weight: .regular)) //
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
        let date = event.chatState?.lastMessageAt
        Text(FormatEvent.hourTime(date ?? Date()))
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color.accent) // isUnreadMessage ? Color.accent : Color(red: 0.42, green: 0.42, blue: 0.42)
            .padding(.trailing, 16)
    }
    
    
    
    private var messageStatus: some View {
        Text(String(3))  //unreadCount
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.white)
            .padding(5)
            .background (
                Circle()
                    .fill(.accent)
            )
    }
}
