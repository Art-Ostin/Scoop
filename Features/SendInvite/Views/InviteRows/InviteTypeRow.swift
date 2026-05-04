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
        DropDownView(verticalOffset: message.isEmpty ? 48 : 24, showOptions: ui.binding(for: .type)) {
            inviteTypeRow
        } dropDown: {
            SelectTypeView(type: $eventType, showMessageScreen: $ui.showMessageScreen, showTypePopup: ui.binding(for: .type), message: message)
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

            DropDownChevron(showTimePopup: ui.binding(for: .type))
                .fixedSize()
                .offset(x: 4)
        }
//        .frame(minHeight: 40, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var typeWithMessage: some View {
        Button {
            openMessageScreen()
        } label: {
            VStack(alignment: .leading) {
                eventSelectedType
                
                (
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.gray)
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
    private var eventSelectedType: some View {
        HStack(spacing: 0){
            Text(eventType.description.label)
                .font(.body(16, .medium))
            
            Text(eventType.description.emoji)
                .font(.body(15, .medium))
//                .offset(y: eventType == .drink || eventType == .socialMeet ? -4 : 0)
                .offset(x: eventType == .socialMeet ? 1 : 0)
        }
        .offset(x: -1)
    }
}

//With No Message Views
extension InviteTypeRow {
    @ViewBuilder private var typeWithNoMessage: some View {
        VStack(alignment: .leading, spacing: 2) {
            eventSelectedType
            addMessageButton
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
        ui.activePopup = nil
        ui.showMessageScreen.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ui.isMessageTap = false
        }
    }
}
/*
 @ViewBuilder
 private var typeWithMessage: some View {
     Button {
         openMessageScreen()
     } label: {
         (
             Text("\(eventType.description.emoji)\(eventType.description.label): ")
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

 */
