//
//  ChatScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 04/03/2026.
//

import SwiftUI

struct ChatScrollView: View {
    @Bindable var vm: ChatViewModel
    var isFocused: FocusState<Bool>.Binding
    let isEvent: Bool
    private let messageAnimation = ChatViewModel.messageAnimation
    @State private var isFirstAppear: Bool = true
    @State private var distanceFromBottom: CGFloat = 0
    
    @State private var scrollPosition = ScrollPosition(idType: String.self)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ClearRectangle(size: 72)
                ChatEventView(event: vm.eventProfile.event)
                messageScrollSection
            }
        }
        //1. The background of the scroll View
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .customScrollFade(height: 100, showFade: true, edge: .top)
        .background(Color.background)
        .scrollIndicators(.hidden)

        //2. Functions to trigger with updates
        .task(id: vm.messages.count == 0) {await loadMessages()} //Scroll to bottom on launch and if flip to zero
        .onChange(of: vm.messages.count) {onMessageSend($0, $1)}
        .onChange(of: isFocused.wrappedValue) { keyboardFocused($1)} //If new keyboard is focused
        
        //3. Track where user is in the ScrollView and if violent move up, turn isFocused to false
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y
        } action: { old, new in
            if new - old < -20 { isFocused.wrappedValue = false}
        }
        
        //4. Tracks where user is in Scroll View updates distance from bottom (used for keyboard focus)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.height - geometry.contentOffset.y - geometry.containerSize.height
        } action: {_, newValue in
            distanceFromBottom = newValue
        }
        
        //5. attach scrollPosition to scroll view so can programmatically scroll
        .scrollPosition($scrollPosition, anchor: .bottom)
    }
}

extension ChatScrollView {
    
    //1. Views for the messages
    private var messageScrollSection: some View {
        ForEach(vm.messages) { message in
            MessageSection(vm: vm, message: message)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    //2.loadMessages on appear
    private func loadMessages() async {
        guard isFirstAppear, !vm.messages.isEmpty else { return }
        scrollToBottomEdge()
        try? await Task.sleep(for: .milliseconds(50))
        scrollToBottomEdge()
        isFirstAppear = false
    }
    
    //3. Logic for sending a message
    private func onMessageSend(_ old: Int, _ new: Int) {
        guard !isFirstAppear, new > old else { return }
        let isOwnMessage = vm.messages.last?.authorId == vm.userId
        guard isOwnMessage || distanceFromBottom < 100 else { return } //scroll to bottom if new message received
        scrollToBottomEdge(animated: true)
    }
    
    //4. Logic for scrolling when is Focused
    private func keyboardFocused(_ focused: Bool) {
        if focused && distanceFromBottom < 250 {
            scrollToBottomEdge(animated: true)
        } else {
            print("Conditions not met")
        }
    }
    
    //5. Scrolling to bottom edge
    private func scrollToBottomEdge(animated: Bool = false) {
        withAnimation(animated ? messageAnimation : nil) {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}



