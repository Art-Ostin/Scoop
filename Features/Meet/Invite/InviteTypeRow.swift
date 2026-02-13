//
//  InviteTypeRow.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct InviteTypeRow: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    
    var event: EventDraft {
        vm.event
    }
    
    var body: some View {
        let trimmedMessage = (event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        HStack {
            //If there is a response in place
            if !trimmedMessage.isEmpty {
                let title = Text(verbatim: "\(event.type.description.emoji ?? "") \(event.type.description.label): ")
                    .font(.body(16, .bold))
                
                let body = Text(" \(trimmedMessage)")
                    .font(.body(12, .italic))
                    .foregroundStyle(vm.isMessageTap ? Color.grayPlaceholder : Color.grayText)
                
                let newText = Text("  edit")
                    .font(.body(12, .italic))
                    .foregroundStyle(vm.isMessageTap ? Color.grayPlaceholder : Color.accent)
                
                (title + body + newText)
                    .lineSpacing(6)
                    .contentShape(.rect)
                    .onTapGesture { openMessageScreen() }
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { vm.isMessageTap = $0 },perform: {}) //Have no actual pressing
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            //Otherwise have this placeholder
            let type = event.type.description.label
            let emoji = event.type.description.emoji ?? ""
            
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(emoji) \(type)")
                        .font(.body(18))
                    Text("Add a Message")
                        .foregroundStyle(vm.isMessageTap ? Color.grayPlaceholder : Color.accent)
                        .font(.body(14))
                        .onTapGesture { openMessageScreen() }
                        .onLongPressGesture(minimumDuration: 0.1,
                                            pressing: { vm.isMessageTap = $0 },
                                            perform: {})
                }
            
            Spacer()
            
            DropDownButton(isExpanded: $vm.showTypePopup)
        }
    }
}

extension InviteTypeRow {
    
    private func openMessageScreen() {
        vm.isMessageTap = true
        vm.showTypePopup = false
        vm.showMessageScreen.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.isMessageTap = false
        }
    }
}
