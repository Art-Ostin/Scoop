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
            noMessageScreen
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

/*
 
 if let eventMessage = vm.respondDraft.originalInvite.event.message {
     RespondTextBubble(showMessageScreen: $showMessageScreen, message: eventMessage, isMyChat: false, showRespondButton: showRespondMessage)
 }
 
 if let respondMessage = vm.respondDraft.respondMessage {
     RespondTextBubble(showMessageScreen: $showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
 }
 
 if vm.respondDraft.respondMessage?.isEmpty != false && vm.respondDraft.originalInvite.event.message?.isEmpty != false {
     noMessageScreen
 }
 */

extension InviteCardMessageView {
    
    
    private var noMessageScreen: some View {
        VStack(spacing: 36) {
            Text("Add a message when you Accept")
                .font(.body(14, .italic))
                .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Button {
                showMessageScreen = true
            } label: {
                Text("Add Message")
                    .font(.body(10, .bold))
                    .foregroundStyle(Color.appGreen)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(.white)
                    .cornerRadius(100)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .inset(by: 0.1)
                            .stroke(Color(red: 0.01, green: 0.6, blue: 0.53), lineWidth: 0.2)
                    )
            }
        }
        .padding(.top, 24)
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
