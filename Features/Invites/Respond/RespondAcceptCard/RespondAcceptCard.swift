//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var isFlipped: Bool
    
    private let sectionSpacing: CGFloat = 24
    
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

    var showMessageRow: Bool {
        displayedMessages != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 22) {
                RespondTitle(isFlipped: $isFlipped, showTimePopup: showTimePopup, event: event, image: vm.image)
                RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
                RespondPlaceRow(showMessageScreen: $showMessageScreen, location: event.location)
            }
            .zIndex(2)
            actionSection
        }
        .zIndex(1)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(customBackground)
        .padding(.horizontal, 24)
        .offset(y: 24) // showMessageRow ? 0 :
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .animation(.easeInOut(duration: 0.2), value: showMessageRow)
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
}




/*
 private var placeRow: some View {
     HStack(spacing: 24) {
         Image("MiniMapIcon")
         let location = event.location
         VStack(alignment: .leading, spacing: 4) {
                 Text(location.name ?? "")
                     .font(.body(17, .medium))
                     .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                 
                 Text(FormatEvent.addressWithoutCountry(location.address))
                     .font(.body(12, .medium))
                     .underline()
                     .foregroundStyle(Color(red: 0.72, green: 0.72, blue: 0.72))
                     .lineLimit(1)
             }
         .frame(maxWidth: .infinity, alignment: .leading)
         
         Image("AddMessageIcon")
             .frame(maxWidth: 40, alignment: .trailing)
     }
 }

 
 respondMessagesView
 
 
 */
