//
//  InviteCardMessageView.swift
//  Scoop
//
//  Created by Art Ostin on 13/04/2026.
//

import SwiftUI

struct InviteCardMessageView: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var showMessageSection: Bool
    @Binding var showMessageScreen: Bool
    var showRespondMessage: Bool {vm.respondDraft.respondMessage?.isEmpty != false}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let eventMessage = vm.respondDraft.originalInvite.event.message {
                RespondTextBubble(showMessageScreen: $showMessageScreen, message: eventMessage, isMyChat: false, showRespondButton: showRespondMessage)
            } else if showRespondMessage {
                noMessageScreen
            }
            if let respondMessage = vm.respondDraft.respondMessage {
                RespondTextBubble(showMessageScreen: $showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
        .overlay(alignment: .bottomTrailing) {
            backToEventButton
                .padding(.bottom)
        }
    }
}

extension InviteCardMessageView {
    
    private var noMessageScreen: some View {
        Button {
            
        } label: {
            Text("Add Message")
        }
    }
    
    private var backToEventButton: some View {
        Button {
            showMessageSection.toggle()
        } label : {
            Text("Event")
                .font(.body(12, .bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(.white)
            .cornerRadius(100)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .inset(by: 0.1)
                    .stroke(Color.appGreen, lineWidth: 0.2)
            )
            .padding(10)
            .contentShape(.rect)
        }
        .padding(-10)
    }
}
