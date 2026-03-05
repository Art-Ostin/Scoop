//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {
    
    @Environment(\.dismiss) private var dismiss
        
    @Bindable var vm: ChatViewModel
    @Bindable var eventVM: EventViewModel
    
    @State var detailsOpen: Bool = false
    @State var selectedProfile: ProfileModel? = nil
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [UIImage] = []
    @State private var isUserScrollingUp  = false
    @State var text = ""
    
    @Namespace private var ns
    
    @FocusState private var isFocused
    
    
    var isEvent = false
    let profileModel: ProfileModel
    
    
    var body: some View {
        ZStack {
            messageView
            
            if let profile = selectedProfile {
                profileView(profile: profile)
            }
        }
        .overlay(alignment: .top) {chatHeaderView}
        .onPreferenceChange(OpenDetails.self) { isDetailsOpen in
            detailsOpen = isDetailsOpen
        }
        .task {
            let loadImages = await vm.loadImages(profileModel: profileModel)
            profileImages = loadImages
        }
    }
}





//Other Views
extension ChatContainer {
    
    private func profileView(profile: ProfileModel) -> some View {
        ProfileView(vm:
                    ProfileViewModel(defaults: eventVM.defaults,
                            sessionManager: eventVM.sessionManager,
                            profileModel: profile,
                            imageLoader: eventVM.imageLoader),
                    profileImages: profileImages,
                    selectedProfile: $selectedProfile,
                    dismissOffset: $dismissOffset, isMessageProfile: true)
        .id(profileModel.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    
    @ViewBuilder
    private func messageBox(idx: Int, message: MessageModel) -> some View {
        let isMyChat = vm.userId == message.authorId
        let newAuthor = checkIfNewAuthor(idx: idx, message: message)
        let nextIsNewAuthor = checkIfNextIsNewAuthor(idx: idx, message: message)
        
        VStack(spacing: 16) {
            if !sameDay(idx, message) {
                ChatDayDivider(date: message.dateCreated)
            }
            MessageBubbleView(chat: message, newAuthor: newAuthor, nextIsNewAuthor: nextIsNewAuthor, isMyChat: isMyChat)
        }
    }
    
    func sameDay(_ idx: Int, _ newMessage: MessageModel) -> Bool {
        guard idx > 0 else {return true}
        guard let lastMessageDay = vm.messages[idx - 1].dateCreated else {return false}
        guard let newMessageDay = newMessage.dateCreated else {return false}
        return Calendar.current.isDate(lastMessageDay, inSameDayAs: newMessageDay)
    }
    
    func checkIfNewAuthor(idx: Int, message: MessageModel) -> Bool {
        return idx == 0 || vm.messages[idx - 1].authorId != message.authorId
    }
    
    func checkIfNextIsNewAuthor(idx: Int, message: MessageModel) -> Bool {
        idx == vm.messages.count - 1 || vm.messages[idx + 1].authorId != message.authorId
    }
    
}
