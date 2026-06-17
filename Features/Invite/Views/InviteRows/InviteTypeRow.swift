//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    
    @Binding var type: Event.EventType
    @Binding var unparsedMessage: String?
    
    @State private var messageHeight: CGFloat = 0
    //The message we last derived a line count from. Lets us ignore height re-measures caused by
    //the margin animation re-wrapping the same text, so the line count (and margin) can't oscillate.
    @State private var lastCountedMessage = ""

    var message: String  {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }


    var body: some View {
            HStack {
                inviteTypeText(.what)
                Spacer(minLength: 16)
                inviteTypeButton
            }
    }
}

//With Message Views
extension InviteTypeRow {
    
    @ViewBuilder
    private var inviteTypeButton: some View {
        CustomMenu(
            onOpen: { ui.popupOpen = true },
            onClose: { ui.popupOpen = false }
        ) {
            SelectTypeView(type: $type, showMessageScreen: $ui.showMessageScreen, showTypePopup: ui.binding(for: .type), message: message)
        } label: {
            inviteTypeIcon
        }
    }
    
    private var inviteTypeIcon: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing) {
                
                Text(type.longTitle) //type.emoji + " " + Removed the Emoji
                    .font(.body(17, .medium))
                    .contentTransition(.opacity)
                    .geometryGroup() //Fixes for clear transition
                
                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.trailing)
                    
                        .onGeometryChange(for: CGFloat.self) { geo in
                            geo.size.height
                        } action: { newValue in
                            messageHeight = newValue
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            Image("InviteChevron")
        }
        .task(id: messageHeight) { updateLineHeight() }       //typing: recount once the new text's height settles
        .onChange(of: message) { _, _ in updateLineHeight() } //clearing/edits: recount (and reset) on text change
    }
    
    
    private func updateLineHeight() {
        //1. No message (incl. clear): reset the count, and the dedupe key so the next message recounts.
        if message.isEmpty {
            ui.messageLineCount = 0
            lastCountedMessage = ""
            return
        }
        guard message != lastCountedMessage, messageHeight > 0 else { return }

        let lineHeight = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        ui.messageLineCount = min(3, Int((messageHeight / lineHeight).rounded()))
        lastCountedMessage = message
    }
    
}
