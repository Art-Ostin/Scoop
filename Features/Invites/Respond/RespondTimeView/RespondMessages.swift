//
//  MessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 31/03/2026.
//

import SwiftUI

struct RespondMessages: View {
    
    @Binding var showMessageScreen: Bool
    
    @Bindable var vm: RespondViewModel
    let showRespondMessage: Bool
    let showTimePopup: Bool
    
    var body: some View {
        
        VStack(spacing: 6) {
            messageOrHourSubtitle
            
            if let response = vm.respondDraft.newTime.message {
                messageSection(message: response, isMine: true)
            }
        }
    }
}

extension RespondMessages {

    @ViewBuilder
    private var messageOrHourSubtitle: some View {
        if let message = vm.respondDraft.event.message {
            messageSection(message: message, isMine: false)
                .overlay(alignment: .bottomTrailing) {
                    if !showRespondMessage {
                        addMessageButton(isEdit: false)
                    }
                }
        } else {
            if let first = vm.respondDraft.event.proposedTimes.firstAvailableDate {
                Text(FormatEvent.hourTime(first))
                    .font(.caption)
                    .foregroundStyle(Color.grayText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func addMessageButton(isEdit: Bool) ->  some View {
        Button {
            showMessageScreen = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isEdit ? "square.and.pencil" : "plus")
                    .font(.system(size: 10, weight: .bold))
                
                Text(isEdit ? "Edit note" : "Add note")
                    .font(.custom("SFProRounded-Bold", size: 11))
                    .kerning(0.4)
            }
            .foregroundStyle(Color.grayText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.92))
            }
            .stroke(24, lineWidth: 1, color: Color.grayBackground)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
        }
        .offset(y: isEdit ?  0 : 20)
    }
    
    @ViewBuilder
    private func messageSection(message: String, isMine: Bool) -> some View {
        let name = isMine ? "You" : vm.respondDraft.event.otherUserName
        Group {
            Text(showRespondMessage ? "\(name) - " : "")
                .foregroundStyle(isMine ? Color.accent.opacity(0.4) : Color.gray)
            +
            Text(message)
        }
        .font(.footnote)
        .foregroundStyle(.gray)
        .opacity(showTimePopup ? 0.1 : 1)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment:.leading)
    }
}
