//  AcceptInvitePopup.swift
//  Scoop
//
//  Created by Art Ostin on 19/03/2026.
//

import SwiftUI

struct RespondAcceptCard: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var isFlipped: Bool
    
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
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .leading, spacing: showMessageRow ? 0 : 16) {
                title
//                RespondTypeRow(isFlipped: $isFlipped, type: vm.respondDraft.originalInvite.event.type, message: vm.respondDraft.originalInvite.event.message, showTimePopup: showTimePopup)
                RespondTimeRow(vm: vm, showTimePopup: $showTimePopup, showMessageScreen: $showMessageScreen)
                placeRow
            }
            .zIndex(3)
            actionSection
                .zIndex(1)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(customBackground)
        .padding(.horizontal, 24)
        .offset(y: showMessageRow ? 0 : 8)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.grayText).opacity(0.8)
                .font(.body(14, .medium))
                .padding()
        }
        .animation(.easeInOut(duration: 0.2), value: showTimePopup)
        .animation(.easeInOut(duration: 0.2), value: vm.respondDraft.respondType)
        .animation(.easeInOut(duration: 0.2), value: showMessageRow)
        .sheet(isPresented: $showMessageScreen) {
            AddMessageView(eventType: .constant(event.type), showMessageScreen: $showMessageScreen, message: $vm.respondDraft.respondMessage, isRespondMessage: true)
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
    
    private var placeRow: some View {
        HStack(spacing: 24) {
            Image("MiniMapIcon")
                .scaleEffect(1.3)
                .foregroundStyle(Color.appGreen)
            
            VStack {
                let location = event.location
                VStack(alignment: .leading) {
                    Text(location.name ?? "")
                        .font(.body(16, .medium))
                    Text(FormatEvent.addressWithoutCountry(location.address))
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .underline()
                        .lineLimit(1)
                }
            }
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
    
    
    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                CirclePhoto(image: vm.image, showShadow: false, height: 25)
                (
                    Text("Drink with \(vm.respondDraft.originalInvite.event.otherUserName)")
                    + Text(" 🍻").baselineOffset(4)
                )
                .font(.custom("SFProRounded-Semibold", size: 20))
            }
            
            if let message = vm.respondDraft.originalInvite.event.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.grayText)
                    .opacity(showTimePopup ? 0.1 : 1)
                    .padding(.leading, 38)
            }
        }
    }
}

/*
 
 Image(systemName: "info.circle")
     .foregroundStyle(Color.grayText).opacity(0.8)
     .font(.body(14, .medium))
     .offset(y: -4)
 */

/*
 //        .overlay(alignment: .topTrailing) {
 //            HStack(spacing: 8) {
 //                Text("Drink with \(vm.respondDraft.originalInvite.event.otherUserName)")
 //                    .font(.custom("SFProRounded-Semibold", size: 20))
 //            }
 //            .padding()
 //            .padding(.trailing, 30)
 //            .padding(.top, 2)
 //        }

 */
