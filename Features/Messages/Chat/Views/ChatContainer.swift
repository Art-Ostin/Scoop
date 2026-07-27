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

    //Local view state
    @State private var profileImages: [UIImage] = []
    @State private var profileTrigger = 0
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
        
        //4. Code to execute and listen for
        .task(id: vm.eventProfile.profile.id) { profileImages = await vm.loadImages(profile: vm.eventProfile) }
        .task(id: vm.eventProfile.id) { await vm.startListening() }
        .onAppear { messageAppearCode() }
        .onDisappear { messageDisappearCode() }
        
        .overlay(alignment: .topLeading) {chatDismissButton }
        .navigationBarBackButtonHidden()
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
            mode: .viewProfile
        )
        .onAppear { isFocused = false }
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
        let avatarSize: CGFloat = 35
        return ScoopButton(shape: .rect(cornerRadius: CornerRadius.xl)) {
            isFocused = false
            profileTrigger += 1
        } label: {
            HStack(spacing: Spacing.xs) {
                SmallImage(image: transitionImages.first ?? UIImage(), size: avatarSize, isCircle: true)
                    .zoomTransition(images: transitionImages, trigger: profileTrigger) {
                        profileView
                    }
                    .scaleEffect(0.9)

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

    private var transitionImages: [UIImage] {
        if !profileImages.isEmpty { return profileImages }
        return vm.eventProfile.image.map { [$0] } ?? []
    }
    
    
    private var chatDismissButton: some View {
        let size: CGFloat = 39
        return ScoopButton(shape: Circle(), action: {dismiss()}) {
            Image(systemName: isEvent ? "xmark" : "chevron.left")
                .font(.system(size: 16, weight: .heavy))
                .frame(width: size, height: size) //Slightly larger than default medium
        }
        .padding(.horizontal)
    }
}
