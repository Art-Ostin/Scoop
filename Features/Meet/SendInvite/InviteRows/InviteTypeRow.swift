//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    
    @Binding var eventType: Event.EventType?
    @Binding var unparsedMessage: String?
    
    var message: String  {
        (unparsedMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        DropDownView(showOptions: $ui.showTypePopup) {
            inviteTypeRow
        } dropDown: {
            SelectTypeView(type: $eventType, showMessageScreen: $ui.showMessageScreen, showTypePopup: $ui.showTypePopup, message: message)
        }
    }
}

//With Message Views
extension InviteTypeRow {
    
    private var inviteTypeRow: some View {
        HStack(spacing: 2) {
            Group {
                if message.isEmpty {
                    typeWithNoMessage
                } else {
                    typeWithMessage
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            DropDownChevron(showTimePopup: $ui.showTypePopup)
                .fixedSize()
                .offset(x: 4)
        }
        .frame(height: ui.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var typeWithMessage: some View {
        Button {
            openMessageScreen()
        } label: {
            if let eventType {
                (
                    Text("\(eventType.description.emoji) \(eventType.description.label): ")
                        .font(.body(16, .bold))
                    + Text(message)
                        .font(.body(14, .medium))
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    + Text("  Edit")
                        .font(.body(12, .bold))
                        .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.accent)
                )
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            }
        }
    }
}

//With No Message Views
extension InviteTypeRow {
    @ViewBuilder private var typeWithNoMessage: some View {
        if let eventType {
            let type = eventType.description.label
            let emoji = eventType.description.emoji
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(emoji) \(type)")
                        .font(.body(18))
                    addMessageButton
                }
        } else {
            Text("Choose a type")
                .font(.body(15, .italic))
        }
    }
    
    private var addMessageButton: some View {
        Text("Add Message")
            .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.accent)
            .font(.body(12, .bold))
            .onTapGesture { openMessageScreen() }
            .onLongPressGesture(minimumDuration: 0.1, pressing: { ui.isMessageTap = $0 }, perform: {})
    }
    
    private func openMessageScreen() {
        ui.isMessageTap = true
        ui.showTypePopup = false
        ui.showMessageScreen.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ui.isMessageTap = false
        }
    }
}

/*
 
 (inviteType + Text(message) + editButton)
     .font(.body(16))
     .lineSpacing(6)
     .contentShape(.rect)
     .onTapGesture { openMessageScreen() }
     .onLongPressGesture(minimumDuration: 0.1, pressing: { ui.isMessageTap = $0 },perform: {}) //Have no actual pressing
     .frame(maxWidth: .infinity, alignment: .leading)

 
 @ViewBuilder
 private var inviteType: some View {
     if let eventType {
         Text(verbatim: "\(eventType.description.emoji) \(eventType.description.label): ")
             .font(.body(16, .bold))
     }
 }
 
 @ViewBuilder private func inviteMessage(trimmed: String) -> Text {
     let parsedMessage = trimmed.count > 65 ? "\(trimmed.prefix(65))..." : trimmed
     Text(" \(parsedMessage)")
         .font(.body(12, .italic))
         .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.grayText)
 }
 
 private var editButton: Text {
     Text(" edit")
         .font(.body(12, .italic))
         .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.accent)
 }

 */
