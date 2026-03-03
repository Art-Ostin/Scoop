//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatView: View {
    
    let profileModel: ProfileModel
    
    @Bindable var vm: EventViewModel
    
    @State var selectedProfile: ProfileModel? = nil
    @State var dismissOffset: CGFloat? = nil
    
    @Environment(\.dismiss) private var dismiss
    var isEvent = false
    @State var profileImages: [UIImage] = []
    
    
    let userId = "user_arthur"
    @State private var isUserScrollingUp  = false
    @State var text = ""
    
    @FocusState private var isFocused
    @State var lastWasSameUser: Bool = false
    
    private let bottomID = "BOTTOM_ANCHOR"
    
    
    let messages = ChatMessageModel.mockChatMessages
    
    var body: some View {
        ZStack {
            messageView
            
            if let profile = selectedProfile {
                profileView(profile: profile)
            }
        }
    }
}


extension ChatView {
    
    private var messageView: some View {
        VStack {
            messageSection
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    typingSection
                }
        }
        .onChange(of: isUserScrollingUp) { oldValue, newValue in
            if newValue && isFocused  {
                isFocused = false
                isUserScrollingUp = false
            }
        }
        //Background doubles up avoids keyboard bug
        .background(Color(red: 0.96, green: 0.95, blue: 0.92).opacity(0.08))
        .background(
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .opacity(0.08)
                .ignoresSafeArea(.keyboard)
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: isEvent ? "xmark" : "chevron.left")
                        .font(.body(16, .bold))
                        .contentShape(Rectangle())
                        .foregroundStyle(Color.black)
                }
            }
            
            if selectedProfile == nil {
                ToolbarItem() {
                    Button {
                        dismissOffset = nil
                        selectedProfile = profileModel
                    } label: {
                        HStack(spacing: 8) {
                            if let image = profileModel.image {
                                CirclePhoto(image: image, showShadow: false)
                            }
                            
                            Text(profileModel.profile.name)
                                .font(.body(17, .bold))
                                                            
                        }
                        .offset(x: -4)
                    }
                }
            }
        }
        .task {
            let loadImages = await vm.loadImages(profileModel: profileModel)
            profileImages = loadImages
        }
    }
    
    private func profileView(profile: ProfileModel) -> some View {
        ProfileView(vm:
                    ProfileViewModel(defaults: vm.defaults,
                            sessionManager: vm.sessionManager,
                            profileModel: profile,
                            imageLoader: vm.imageLoader),
                    profileImages: profileImages,
                    selectedProfile: $selectedProfile,
                    dismissOffset: $dismissOffset, isMessageProfile: true)
        .id(profileModel.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private var typingSection: some View {
        HStack (alignment: .bottom, spacing: 6) {
            
            TextField("Message...", text: $text, axis: .vertical)
                .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .glassIfAvailable(RoundedRectangle(cornerRadius: 24), isClear: false)
                .lineSpacing(4)
                .focused($isFocused)
                .lineLimit(1...5)
            
            
        
            Button {
                print("Hello World")
            } label: {
                ZStack {
                    Circle()
                        .fill(text.isEmpty ? Color.grayBackground : Color.accent)
                    
                    Image("SendArrow")
                        .scaleEffect(0.8)
                }
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(text.isEmpty ? 0 : 0.1), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.bottom, isFocused ? 12 : 0)
    }
    
    private var messageSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(messages.indices, id: \.self) { idx in
                        let chat = messages[idx]
                        messageBox(idx: idx, chat: chat)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self, of: { g in
                g.contentOffset.y
            }, action: { oldY, newY in
                let directionThreshold: CGFloat = 24
                let delta = newY - oldY
                guard abs(delta) > directionThreshold else { return }
                isUserScrollingUp = (delta < 0)
            })
            .frame(maxWidth: .infinity)
            
            // Example trigger:
            .onChange(of: isFocused) { _, newValue in
                guard newValue else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageBox(idx: Int, chat: ChatMessageModel) -> some View {
        let chat = messages[idx]
        let prevIsDifferentUser =
        idx == 0 || messages[idx - 1].authorId != chat.authorId
        let nextIsDifferentUser =
        idx == messages.count - 1 || messages[idx + 1].authorId != chat.authorId
        
        var checkNewDay: Bool {
            if idx == 0 {
                return true
            } else {
                let lastMessage = messages[idx - 1]
                return isNewDay(lastMessage, chat)
            }
        }
        
        let isMyChat = userId == chat.authorId
        
        
        VStack(spacing: 16) {
            
            if checkNewDay {
                if let date = chat.dateCreated {
                    Text(formatDay(day: date))
                        .font(.body(12, .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .stroke(16, lineWidth: 1, color: .grayPlaceholder)
                        .padding(.top, 16)
                }
            }
            
            ChatMessageView(chat: chat, isMyChat: isMyChat, nextIsDifferentUser: nextIsDifferentUser, lastIsDifferentUser: prevIsDifferentUser)
                .padding(.bottom, nextIsDifferentUser ? 12 : 0)
        }
    }
    
    func formatDay(day: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        
        let startDay = cal.startOfDay(for: day)
        let startNow = cal.startOfDay(for: now)
        let diffDays = cal.dateComponents([.day], from: startDay, to: startNow).day ?? 0
        
        // 2–6 days ago → weekday name
        if (2...6).contains(diffDays) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "EEEE" // Wednesday
            return df.string(from: day).capitalized(with: .current)
        }
        
        // 7+ days ago (or future) → "Tue 3 Feb"
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEE d MMM"
        return df.string(from: day)
    }
    
    func isNewDay(_ lastMessage: ChatMessageModel, _ newMessage: ChatMessageModel) -> Bool {
        if let lastMessageDay = lastMessage.dateCreated, let newMessageDay = newMessage.dateCreated {
            return !Calendar.current.isDate(lastMessageDay, inSameDayAs: newMessageDay)
        }
        return false
    }
}

//Original Typing Section
/*
 private var typingSection: some View {
     HStack (alignment: .bottom, spacing: 6) {
         TextField("Message…", text: $text, axis: .vertical)
             .frame(minHeight: 24, alignment: .center)
             .lineLimit(1...4)
             .padding(.horizontal)
             .padding(.vertical, 8)
             .background(
                 RoundedRectangle(cornerRadius: 24)
                     .fill(Color.white)
             )
             .stroke(24, lineWidth: 1, color: .grayPlaceholder)
             .focused($isFocused)
             .lineSpacing(4)
         
         Button {
             print("Hello World")
         } label: {
             ZStack {
                 Circle()
                     .fill(text.isEmpty ? Color.grayBackground : Color.accent)
                 
                 Image("SendArrow")
             }
             .frame(width: 44, height: 44)
         }
         .buttonStyle(.plain)
     }
     .frame(maxWidth: .infinity)
     .padding(.top, 12)
     .padding(.horizontal)
     .padding(.bottom, isFocused ? 12 : 0)
     .background(Color.background)
 }
 */

/*
 VStack {
     messageSection
         .safeAreaInset(edge: .bottom, spacing: 0) {
             typingSection
         }
 }
 .onChange(of: isUserScrollingUp) { oldValue, newValue in
     if newValue && isFocused  {
         isFocused = false
         isUserScrollingUp = false
     }
 }
 //Background doubles up avoids keyboard bug
 .background(Color.background)
 .background(
     Color.background
         .ignoresSafeArea(.keyboard)
 )
 .toolbar {
     ToolbarItem(placement: .topBarLeading) {
         Button {
             dismiss()
         } label: {
             Image(systemName: isEvent ? "xmark" : "chevron.left")
                 .font(.body(16, .bold))
                 .contentShape(Rectangle())
                 .foregroundStyle(Color.black)
         }
     }
     
     ToolbarItem() {
         Button {
             selectedProfile = profileModel
         } label: {
             HStack(spacing: 8) {
                 if let image = profileModel.image {
                     CirclePhoto(image: image, showShadow: false)
                 }
                 
                 Text(profileModel.profile.name)
                     .font(.body(17, .bold))
                                                 
             }
             .padding(.trailing, 6)
         }
     }
 }
 */
