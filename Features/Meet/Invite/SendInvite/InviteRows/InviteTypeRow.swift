//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    @Bindable var ui: TimeAndPlaceUIState
    
    var event: EventDraft {vm.event}
    var message: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        DropDownView(showOptions: $ui.showTypePopup) {
            inviteTypeRow
        } dropDown: {
            SelectTypeView(vm: vm, ui: ui, selectedType: vm.event.type, showTypePopup: $ui.showTypePopup)
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
        Text(verbatim: "\(event.type.description.emoji) \(event.type.description.label): ")
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
        let type = event.type.description.label
        let emoji = event.type.description.emoji
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
