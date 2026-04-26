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
    
    var hasInviteMessage: Bool { vm.respondDraft.originalInvite.event.message?.isEmpty == false }
    var hasRespondMessage: Bool { vm.respondDraft.respondMessage?.isEmpty == false }

    var hasNoMessages: Bool { !hasInviteMessage && !hasRespondMessage }
    var isOnlyInviteMessage: Bool { hasInviteMessage && !hasRespondMessage }
    var isOnlyRespondMessage: Bool { !hasInviteMessage && hasRespondMessage }
    var hasBothMessages: Bool { hasInviteMessage && hasRespondMessage }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasNoMessages {
                noMessageScreen
            } else if isOnlyInviteMessage {
                onlyInviteMessageView
            } else if isOnlyRespondMessage {
                onlyRespondMessageView
            } else if hasBothMessages {
                bothMessagesView
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}


extension InviteCardMessageView {
    
    private enum Palette {
        static let supportingText = Color.grayText.opacity(0.95)
    }
    
    private var noMessageScreen: some View {
        VStack(spacing: 36) {
            addMessageView
            addMessageButton(sayRespond: false)
        }
        .padding(.top, 24)
    }
    
    @ViewBuilder
    private var onlyInviteMessageView: some View {
            if let inviteMessage = vm.respondDraft.originalInvite.event.message {
                RespondTextBubble(showMessageScreen: $showMessageScreen, message: inviteMessage, isMyChat: false, showRespondButton: true)
                    .padding(.top, 24)
            }
    }
    
    private var onlyRespondMessageView: some View {
        VStack(spacing: 36) {
            if let respondMessage = vm.respondDraft.respondMessage {
                addMessageView
                RespondTextBubble(showMessageScreen: $showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
            }
        }
    }
    
    @ViewBuilder
    private var bothMessagesView: some View {
        if let eventMessage = vm.respondDraft.originalInvite.event.message {
            RespondTextBubble(showMessageScreen: $showMessageScreen, message: eventMessage, isMyChat: false)
        }
        
        if let respondMessage = vm.respondDraft.respondMessage {
            RespondTextBubble(showMessageScreen: $showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
        }
    }
    
    
    private func addMessageButton(sayRespond: Bool) -> some View {
        Button {
            showMessageScreen = true
        } label: {
            Text(sayRespond ? "Respond" : "Add Message")
                .font(.body(11, .bold))
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
    
    private var addMessageView: some View {
        Text("Add a message when you Accept")
            .font(.body(13, .medium))
            .foregroundStyle(Palette.supportingText)
            .frame(maxWidth: .infinity, alignment: .center)
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


/*
 
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

 /*
  if vm.respondDraft.respondMessage?.isEmpty == true {
      noMessageScreen
  } else {
      if let respondMessage = vm.respondDraft.respondMessage {
          RespondTextBubble(showMessageScreen: $showMessageScreen, message: respondMessage, isMyChat: true, isNewTime: vm.responseType == .modified)
      }
  }

  */
 */
