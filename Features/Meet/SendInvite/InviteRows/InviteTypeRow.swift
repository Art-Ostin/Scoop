//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    
    @Binding var eventType: Event.EventType
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
        HStack {
            if message.isEmpty {
                typeWithNoMessage
            } else {
                typeWithMessage
            }
            Spacer()
            DropDownButton(isExpanded: $ui.showTypePopup)
        }
        .frame(height: ui.rowHeight)
    }
    
    private var typeWithMessage: some View {
        (inviteType + inviteMessage(trimmed: message) + editButton)
            .lineSpacing(6)
            .contentShape(.rect)
            .onTapGesture { openMessageScreen() }
            .onLongPressGesture(minimumDuration: 0.1, pressing: { ui.isMessageTap = $0 },perform: {}) //Have no actual pressing
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var inviteType: Text {
        Text(verbatim: "\(eventType.description.emoji) \(eventType.description.label): ")
            .font(.body(16, .bold))
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
}

//With No Message Views
extension InviteTypeRow {
    @ViewBuilder private var typeWithNoMessage: some View {
        let type = eventType.description.label
        let emoji = eventType.description.emoji
            VStack(alignment: .leading, spacing: 6) {
                Text("\(emoji) \(type)")
                    .font(.body(18))
                
                addMessageButton
            }
    }
    
    private var addMessageButton: some View {
        Text("Add a Message")
            .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.accent)
            .font(.body(14))
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
