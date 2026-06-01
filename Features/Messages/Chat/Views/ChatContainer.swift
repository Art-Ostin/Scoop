//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {

    //0. Dismiss Profile
    @Environment(\.dismiss) private var dismiss
    
    //1. View Model
    @State private var vm: ChatViewModel

    //2. Different states either: (1) Profile Open (2) isFocused
    @State var profileOpen: Bool = false
    @State var profileRendered: Bool = false
    @FocusState private var isFocused

    //3. Load Profile Images
    @State var profileImages: [UIImage] = []
    
    //4.if ChatContainer for events its different
    let isEvent: Bool

    init(
        defaults: DefaultsManaging,
        session: Session,
        chatRepo: ChatRepository,
        imageLoader: ImageLoading,
        eventProfile: EventProfile,
        isEvent: Bool = false
    ) {
        _vm = State(initialValue: ChatViewModel(
            defaults: defaults,
            session: session,
            chatRepo: chatRepo,
            imageLoader: imageLoader,
            eventProfile: eventProfile
        ))
        self.isEvent = isEvent
    }
    
    var body: some View {
        ChatScrollView(vm: vm, isFocused: $isFocused, isEvent: isEvent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TypeMessageView(vm: vm, isFocused: $isFocused)
                    .overlay(alignment: .bottom) {
                        LinearGradient.appCanvasFade(startPoint: .bottom, endPoint: .top)
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                            .offset(y: 35)
                    }
            }
            .zIndex(2)

            //1. The background and scope
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())

            //2. The overlay and structure
            .overlay(alignment: .topTrailing) { profileButton}
            .overlay { if profileRendered { profileView } }
            .overlay(alignment: .top) { chatDismissButton }

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
    }
}

//Other Views
extension ChatContainer {
    
    private var profileView: some View {
        ProfileView(
            vm: ProfileViewModel(
                profile: vm.eventProfile.profile,
                event: vm.eventProfile.event,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            isMessageProfile: true, //Only time Message Profile so different load
            profileImages: profileImages,
            mode: .viewProfile,
            onDismiss: { profileRendered = false },
            onDismissStart: { profileOpen = false }
        )
        .id(vm.eventProfile.profile.id)
        .zIndex(1)
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .identity))
    }
        
    private func messageAppearCode() {
        vm.session.activeChatEventId = vm.eventProfile.id
        vm.session.notifications.dismiss(where: { $0.eventId == vm.eventProfile.id })
    }
    
    private func messageDisappearCode() {
        if vm.session.activeChatEventId == vm.eventProfile.id {
            vm.session.activeChatEventId = nil
        }
    }
    
    private var profileButton: some View {
        GlassButton(shape: .roundedRect(24)) {
            onProfileTap()
        } buttonLabel: {
            profileLabel
        }
        .padding(.horizontal)
    }
    
    //See if I can simplify this
    private func onProfileTap () {
        var t = Transaction(animation: .spring(duration: 0.2, bounce: 0.1))
        t.disablesAnimations = false
        withTransaction(t) {
            profileRendered = true
            profileOpen = true
        }
    }
    
    private var profileLabel: some View {
        HStack(spacing: 6) {
            CirclePhoto(image: profileImages.first ?? UIImage(), showShadow: false)
                .scaleEffect(0.9)
            
            Text(vm.eventProfile.profile.name)
                .font(.body(16, .bold))
                .foregroundStyle(Color.black)
        }
    }
    
    
    private var chatDismissButton: some View {
        GlassButton(padding: profileOpen ? 6 : 12) {
            dismiss()
        } buttonLabel: {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .font(.body(profileOpen ? 16 : 18, .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

/*
 private var chatHeaderBar: some View {
     ChatHeaderBar(
         profileOpen: $profileOpen,
         image: profileImages.first ?? UIImage(),
         name: vm.eventProfile.profile.name,
         isEvent: isEvent
     )
 }

 */
