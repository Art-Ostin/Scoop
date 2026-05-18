//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {

    //1. View Model
    @State private var vm: ChatViewModel

    //2. Different states either: (1) Profile Open (2) isFocused
    @State var profileOpen: Bool = false
    @FocusState private var isFocused

    //3. Load Profile Images
    @State var profileImages: [UIImage] = []
    
    //4.if ChatContainer for events its different
    let isEvent: Bool

    init(vm: ChatViewModel, isEvent: Bool = false) {
        _vm = State(initialValue: vm)
        self.isEvent = isEvent
    }
    
    var body: some View {
        ZStack{
            ChatScrollView(vm: vm, isFocused: $isFocused, isEvent: isEvent)
            
            if profileOpen {
                profileView
            }
        }
        
        //1. The background and scope
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background.ignoresSafeArea())
        .customScrollFade(height: 100, showFade: true)
        
        //2. The overlay and structure
        .overlay(alignment: .top) { chatHeaderBar }
        .overlay(alignment: .bottom) { typeMessageView }
        
        //3. Hide the toolbar
        .toolbar(.hidden)
        
        //4. Code to execute and listen for
        .task(id: vm.eventProfile.profile.id) { profileImages = await vm.loadImages(profile: vm.eventProfile) }
        .task(id: vm.eventProfile.id) { await vm.startListening() }
        .onAppear { messageAppearCode() }
        .onDisappear { messageDisappearCode() }
        
        //5. when profile opened, turn isFocused to false
        .onChange(of: profileOpen) { oldValue, newValue in
            if newValue {isFocused = false}
        }
        .animation(.spring(duration: 0.32, bounce: 0.1), value: profileOpen)
    }
}

//Other Views
extension ChatContainer {
    
    private var chatHeaderBar: some View {
        ChatHeaderBar(
            profileOpen: $profileOpen,
            image: profileImages.first ?? UIImage(),
            name: vm.eventProfile.profile.name,
            isEvent: isEvent
        )
    }

    private var profileView: some View {
        ProfileView(
            vm: ProfileViewModel(
                profile: vm.eventProfile.profile,
                event: vm.eventProfile.event,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            profileImages: profileImages,
            mode: .viewProfile,
            onDismiss: { profileOpen = false }
        )
        .id(vm.eventProfile.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private var typeMessageView: some View {
        TypeMessageView(vm: vm, isFocused: $isFocused)
            .opacity(profileOpen ? 0 : 1)
    }
    
    private func messageAppearCode() {
        vm.session.activeChatEventId = vm.eventProfile.id
        if vm.session.recentMessageReceived?.eventId == vm.eventProfile.id {
            vm.session.recentMessageReceived = nil
        }
    }
    
    private func messageDisappearCode() {
        if vm.session.activeChatEventId == vm.eventProfile.id {
            vm.session.activeChatEventId = nil
        }
    }
}

