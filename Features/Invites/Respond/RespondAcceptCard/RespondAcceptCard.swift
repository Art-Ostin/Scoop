//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var isFlipped: Bool
    
    private enum Layout {
        static let titleToTimeSpacing: CGFloat = 12
        static let timeToPlaceSpacing: CGFloat = 14
        static let actionTopSpacing: CGFloat = 20
        
        static let horizontalPadding: CGFloat = 22
        static let topPadding: CGFloat = 18
        static let bottomPadding: CGFloat = 18
        
        static func placeToMessageSpacing(hasResponseMessage: Bool) ->  CGFloat {
            hasResponseMessage ? 16 : 22
        }
    }
    
    @State private var showTimePopup: Bool = false
    @State private var showMessageScreen: Bool = false
    
    var event: UserEvent {
        vm.respondDraft.originalInvite.event
    }
    
    private var displayedMessages: (original: String, reply: String)? {
        guard
            let originalMessage = nonEmptyMessage(event.message),
            let replyMessage = nonEmptyMessage(vm.respondDraft.respondMessage)
        else {
            return nil
        }
        return (originalMessage, replyMessage)
    }
    
    private var showMessages: Bool { displayedMessages != nil}

    private var hasEventMessage: Bool {
        nonEmptyMessage(event.message) != nil
    }
    
    private var hasNoEventMessages: Bool {
        nonEmptyMessage(vm.respondDraft.respondMessage) == nil
        && nonEmptyMessage(event.message) == nil
    }
    
    private var hasResponseMessage: Bool {
        vm.respondDraft.respondMessage?.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RespondTitle(isFlipped: $isFlipped, showTimePopup: showTimePopup, event: event, image: vm.image)
                .padding(.bottom, Layout.titleToTimeSpacing)
            RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
                .padding(.bottom, Layout.timeToPlaceSpacing)
            RespondPlaceRow(showMessageScreen: $showMessageScreen, location: event.location, noEventMessages: hasNoEventMessages)
            messageSection
                .padding(.top, Layout.placeToMessageSpacing(hasResponseMessage: hasResponseMessage))
            actionSection
                .padding(.top, Layout.actionTopSpacing)
        }
        .zIndex(1)
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, Layout.topPadding)
        .padding(.bottom, Layout.bottomPadding)
        .frame(maxWidth: .infinity)
        .background(customBackground)
        .padding(.horizontal, 24)
        .offset(y: 24) // showMessageRow ? 0 :
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .sheet(isPresented: $showMessageScreen) {
            AddMessageView(eventType: .constant(event.type), showMessageScreen: $showMessageScreen, message: $vm.respondDraft.respondMessage, isRespondMessage: true, name: vm.respondDraft.newTime.event.otherUserName)
        }
    }
}

extension RespondAcceptCard {
    @ViewBuilder
    private var respondMessagesView: some View {
        if let messages = displayedMessages {
            RespondMessagesView(
                originalMessage: messages.original,
                replyMessage: messages.reply,
                showMessageScreen: $showMessageScreen
            )
        }
    }

    private var actionSection: some View {
        HStack {
            DeclineButton {vm.decline()}
            Spacer()
            AcceptButton(isModified: vm.respondDraft.respondType != .original) { vm.accept()}
        }
    }
    
    private var customBackground: some View {
        ZStack { //Background done like this to fix bugs when popping up
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.background)
                .surfaceShadow(.card, strength: showTimePopup ? 0 : 1)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.grayBackground, lineWidth: 0.5)
            }
    }

    private func nonEmptyMessage(_ message: String?) -> String? {
        guard let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
    
    @ViewBuilder
    private var messageSection: some View {
        if let originalMessage = nonEmptyMessage(event.message) {
            VStack(alignment: .leading, spacing: 12) {
                RespondMessageBubble(showMessageScreen: $showMessageScreen, message: originalMessage, isMyChat: false, hasMessageResponse: hasResponseMessage, isNewTime: vm.responseType == .modified)
                
                if let replyMessage = nonEmptyMessage(vm.respondDraft.respondMessage) {
                    RespondMessageBubble(showMessageScreen: $showMessageScreen, message: replyMessage, isMyChat: true, hasMessageResponse: true, isNewTime: vm.responseType == .modified)
                }
            }
        }
    }
}
