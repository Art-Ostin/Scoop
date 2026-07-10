//
//  ChatView.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI
import UIKit


struct ChatContainer: View {
    
    //Injected
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ChatViewModel
    let isEvent: Bool

    //Local view state (profileMorph owned here so it shadows any morph injected by a presenting container)
    @State private var profileOpen: Bool = false
    @State private var profileRendered: Bool = false
    @State private var profileImages: [UIImage] = []
    @State private var profileMorph = ProfileMorphState()
    @FocusState private var isFocused

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
                MessageInputBar(vm: vm, isFocused: $isFocused)
            }
            .zIndex(2)

            //1. The background and scope
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appCanvas.ignoresSafeArea())
            .customScrollFade(height: 135, edge: .top, isStrong: true)
            .overlay(alignment: .topTrailing) {profileButton}

            //2. The profile presents above the root TabView (behind it here, the
            //chat is what's revealed during the zoom dismissal — the bar stays
            //hidden path-based while a chat is pushed).
            .profileView(presentedID: profileRendered ? vm.eventProfile.profile.id : nil) {
                if profileRendered { profileView }
            }
        
        //4. Code to execute and listen for
        .task(id: vm.eventProfile.profile.id) { profileImages = await vm.loadImages(profile: vm.eventProfile) }
        .task(id: vm.eventProfile.id) { await vm.startListening() }
        .onAppear { messageAppearCode() }
        .onDisappear { messageDisappearCode() }
        
        //5. when profile opened, turn isFocused to false
        .onChange(of: profileOpen) { oldValue, newValue in
            if newValue {isFocused = false}
        }
        .overlay(alignment: .topLeading) {chatDismissButton }
        .navigationBarBackButtonHidden()
        .profileMorphHost(profileMorph)
    }
}

//Other Views
extension ChatContainer {

    private var profileView: some View {
        ProfileContainer(
            vm: ProfileViewModel(
                profile: vm.eventProfile.profile,
                event: vm.eventProfile.event,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            profileImages: profileImages,
            mode: .viewProfile,
            onDismiss: { profileRendered = false },
            onDismissStart: { profileOpen = false }
        )
        .id(vm.eventProfile.profile.id)
        //Cross-fades in the same 0.3s transaction as the circle-photo flight.
        .opacity(profileMorph.contentOpacity)
        //Rendered at the app root, outside this container's environment.
        .environment(profileMorph)
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
    
    
    private func onProfileTap () {
        guard !profileRendered else { return }
        profileMorph.beginOpen(id: vm.eventProfile.profile.id, image: profileImages.first)
        profileRendered = true
        profileOpen = true
    }

    private var profileButton: some View {
        let avatarSize: CGFloat = 35
        return ScoopButton(shape: .rect(cornerRadius: CornerRadius.xl)) {
            onProfileTap()
        } label: {
            HStack(spacing: Spacing.xs) {
                SmallImage(image: profileImages.first ?? UIImage(), size: avatarSize, isCircle: true)
                    .scaleEffect(0.9)
                    .profileMorphSource(id: vm.eventProfile.profile.id, cornerRadius: avatarSize / 2, visualScale: 0.9)

                Text(vm.eventProfile.profile.name)
                    .font(.body(16, .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(height: 39) //Same height as medium buttons keeps consistency
            .padding(.trailing, Spacing.xs)
            .padding(.leading, Spacing.hairline)
        }
        .padding(.horizontal)
    }
    
    
    private var chatDismissButton: some View {
        let size: CGFloat =  profileOpen ? 30 : 39
        return ScoopButton(shape: Circle(), action: {dismiss()}) {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .font(.system(size: profileOpen ? 14 : 16, weight: .heavy))
                .frame(width: size, height: size) //Slightly larger than default medium
        }
        .padding(.horizontal)
    }
}
