//
//  MessageSection.swift
//  Scoop
//
//  Created by Art Ostin on 31/03/2026.
//

import SwiftUI
import ChatBubble


struct RespondMessages: View {
    
    @Binding var showMessageScreen: Bool
    
    @Bindable var vm: RespondViewModel
    let showTimePopup: Bool
    
    var showMessageResponse: Bool {
        vm.respondDraft.newTime.message?.isEmpty == false
    }

    var body: some View {
        
        VStack(spacing: showMessageResponse ? 24 : 10) {
            if !showMessageResponse {
                messageOrHourSubtitle
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let message = vm.respondDraft.event.message
                    
                    
                    
                    {
                        MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: message), newAuthor: true, nextIsNewAuthor: true, isMyChat: false, isInviteMessage: true)
                    }
                    
                    if let newMessage = vm.respondDraft.newTime.message  {
                        MessageBubbleView(chat: MessageModel(authorId: "", recipientId: "", content: newMessage), newAuthor: true, nextIsNewAuthor: true, isMyChat: true, isInviteMessage: true)
                    }
                }
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
                    if !showMessageResponse {
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
                    .fill(showMessageResponse ? Color.clear : Color.white.opacity(0.92))
            }
            .stroke(24, lineWidth: 1, color: showMessageResponse ? Color.clear : Color.grayBackground)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(.rect)
        }
        .offset(y: isEdit ?  0 : 20)
    }
    
    
    @ViewBuilder
    private func messageSection(message: String, isMine: Bool) -> some View {
        let name = isMine ? "You" : vm.respondDraft.event.otherUserName
        
        Group {
            Text( showMessageResponse ? "\(name) - " : "")
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
    
    
    private func messageCard(message: String, name: String, isMyChat: Bool) -> some View {
        Text(message)
            .font(.body(14, .regular))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .surfaceShadow(.card, strength: showTimePopup ? 0 : 0.3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.grayBackground, lineWidth: 1)
            }
            .opacity(showTimePopup ? 0.08 : 1)
            .overlay(alignment: .topLeading) {
                messageCardTitle(name)
                    .padding(.leading, 18)
                    .alignmentGuide(.top) { dimensions in
                        dimensions[VerticalAlignment.center]
                    }
            }
            .overlay(alignment: .topTrailing) {
                if isMyChat {
                    editButton
                        .padding(.trailing, 18)
                        .alignmentGuide(.top) { dimensions in
                            dimensions[VerticalAlignment.center]
                        }
                }
            }
            .onTapGesture {
                if isMyChat {showMessageScreen.toggle()}
            }
        
    }
    
    private func messageCardTitle(_ name: String) -> some View {
        Text("  \(name)  ")
            .font(.custom("SFProRounded-Bold", size: 12))
            .foregroundStyle(name == "You" ? Color.accent.opacity(0.8) : Color.black.opacity(0.72))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.background, location: 0.0),
                                .init(color: Color.white, location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
    
    private var editButton: some View {
        HStack(spacing: 2) {
            Text("Edit")
                .font(.custom("SFProRounded-Bold", size: 12))
                .foregroundStyle(Color.accent)

            Image(systemName: "square.and.pencil")
                .font(.system(size: 10, weight: .bold))
                .padding(.trailing, 18)
                .alignmentGuide(.top) {dimensions in
                    dimensions[VerticalAlignment.top]
                }
                .foregroundStyle(Color.accent)
        }
    }
}

/*
 
 Text(message)
     .font(.body(14, .regular))
     .lineSpacing(6)
     .fixedSize(horizontal: false, vertical: true)
     .frame(maxWidth: .infinity, alignment: .leading)
     .frame(maxWidth: .infinity, alignment: .leading)
     .chatBubble(
         position: .leadingBottom,
         cornerRadius: 18,
         color: .white
     )
 */
