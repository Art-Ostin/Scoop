//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var ui: TimeAndPlaceUIState
    let event: EventDraft
    var trimmedMessage: String  {
        (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        
        
        DropDownView(showOptions: $vm.showTypePopup) {
            InviteTypeRow(vm: vm)
                .frame(height: 50)
        } dropDown: {
            SelectTypeView(vm: vm, selectedType: vm.event.type, showTypePopup: $vm.showTypePopup)
        }

        
        
        
        HStack {
            if !trimmedMessage.isEmpty {
                typeWithMessage
            } else {
                typeWithNoMessage
            }
            Spacer()
            DropDownButton(isExpanded: $ui.showTypePopup)
        }
    }
}

extension InviteTypeRow {
    
    private var typeWithMessage: some View {
        (inviteType + inviteMessage(trimmed: trimmedMessage) + editButton)
            .lineSpacing(6)
            .contentShape(.rect)
            .onTapGesture { openMessageScreen() }
            .onLongPressGesture(minimumDuration: 0.1, pressing: { ui.isMessageTap = $0 },perform: {}) //Have no actual pressing
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var inviteType: some View {
        Text(verbatim: "\(event.type.description.emoji ?? "") \(event.type.description.label): ")
            .font(.body(16, .bold))
    }
    
    @ViewBuilder private func inviteMessage(trimmed: String) -> some View {
        let parsedMessage = trimmed.count > 65 ? "\(trimmed.prefix(65))..." : trimmed
        Text(" \(parsedMessage)")
            .font(.body(12, .italic))
            .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.grayText)
    }
    
    private var editButton: some View {
        Text(" edit")
            .font(.body(12, .italic))
            .foregroundStyle(ui.isMessageTap ? Color.grayPlaceholder : Color.accent)

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

//
extension InviteTypeRow {
    
    @ViewBuilder
    private var typeWithNoMessage: some View {
        let type = event.type.description.label
        let emoji = event.type.description.emoji ?? ""
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
}
