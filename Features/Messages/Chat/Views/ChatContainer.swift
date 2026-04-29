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
        ZStack{
            Color.background.ignoresSafeArea()
            ChatScrollView(vm: vm, isFocused: $isFocused, isEvent: isEvent)
            if isProfileOpen != nil { profileView}
        }
        .overlay(alignment: .top) {chatHeaderBar} //{if isEvent {chatHeaderBar}}
        .overlay(alignment: .bottom) {typeMessageView}
        .task(id: vm.eventProfile.profile.id) { profileImages = await vm.loadImages(profile: vm.eventProfile)}
        .task(id: vm.eventProfile.id) { await vm.startListening() }
        .onAppear {
            vm.session.activeChatEventId = vm.eventProfile.id
            if vm.session.recentMessageReceived?.eventId == vm.eventProfile.id {
                vm.session.recentMessageReceived = nil
            }
        }
        .onDisappear {
            if vm.session.activeChatEventId == vm.eventProfile.id {
                vm.session.activeChatEventId = nil
            }
        }
        .hideTabBar()
        .toolbar(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customScrollFade(height: 100, showFade: true)
    }
}

//Other Views
extension ChatContainer {
    
    @ViewBuilder
    private var profileButtonMessage: some View {
        if !isEvent {
            Button {
                openProfile()
            } label: {
                HStack(spacing: 6) {
                    CirclePhoto(image: profileImages.first ?? UIImage(), showShadow: false)
                        .scaleEffect(0.9)
                    
                    Text(vm.eventProfile.profile.name)
                        .font(.body(16, .bold))
                }
                .padding(.horizontal, -4)
                .padding(.vertical, -3)
            }
        }
    }
    
    private func openProfile() {
        isFocused = false
        dismissOffset = nil
        withAnimation(.easeInOut(duration: 0.2)) {isProfileOpen = vm.eventProfile.profile}
    }

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
            mode: .viewProfile)
        .id(vm.eventProfile.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private var typeMessageView: some View {
        TypeMessageView(vm: vm, isFocused: $isFocused)
            .opacity(isProfileOpen == nil ? 1 : 0)
    }
}
