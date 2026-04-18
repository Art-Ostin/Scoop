//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {
    
    @Bindable var vm: ChatViewModel
    
    @State var isProfileOpen: UserProfile? = nil
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [UIImage] = []
    @FocusState private var isFocused
    
    var isEvent = true
    
    var body: some View {
        ZStack {
            ChatScrollView(vm: vm, isFocused: $isFocused, isEvent: isEvent)

            if isProfileOpen != nil {
                profileView
            }
        }
        .overlay(alignment: .top) {if !isEvent {chatHeaderBar}}
        .overlay(alignment: .bottom) {typeMessageView}
        .task { profileImages = await vm.loadImages(profile: vm.eventProfile)}
        .hideTabBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                
                ProfileButton(image: vm.image, profile: profile, dismissOffset: $dismissOffset, isProfileOpen: $isProfileOpen, isFocused: isFocused)
            }
        }
    }
}

//Other Views
extension ChatContainer {
    
    private var chatHeaderBar: some View {
        ChatHeaderBar(
            isProfileOpen: $isProfileOpen,
            dismissOffset: $dismissOffset,
            profile: vm.eventProfile.profile,
            image: profileImages.first ?? UIImage(),
            isEvent: isEvent,
            isFocused: $isFocused
        )
    }
    
    private var profileView: some View {
        ProfileView(
            vm: ProfileViewModel(
                defaults: vm.defaults,
                s: vm.session,
                profile: vm.eventProfile.profile,
                event: vm.eventProfile.event,
                imageLoader: vm.imageLoader
            ),
            profileImages: profileImages,
            selectedProfile: $isProfileOpen,
            dismissOffset: $dismissOffset,
            isMessageProfile: true
        )
        .id(vm.eventProfile.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private var typeMessageView: some View {
        TypeMessageView(vm: vm, isFocused: $isFocused)
            .opacity(isProfileOpen == nil ? 1 : 0)
    }
}
