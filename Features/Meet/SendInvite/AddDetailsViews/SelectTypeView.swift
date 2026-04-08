//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {
    
    @Binding var type: Event.EventType
    @Binding var showMessageScreen: Bool
    @Binding var showTypePopup: Bool
    
    let message: String
    
    var body: some View {
        DropDownMenu {
            ForEach(Event.EventType.allCases, id: \.self) {eventType in
                inviteDropDownRow(eventType: eventType)
            }
        }
    }
}
extension SelectTypeView {
    
    @ViewBuilder
    private func inviteDropDownRow(eventType: Event.EventType) -> some View {
        let notLastRow = eventType != Event.EventType.allCases.last
        VStack(spacing: 18) {
            HStack(spacing: 24) {
                Text(eventType.description.emoji)
                Text(eventType.description.label)
                Spacer()
            }
            if notLastRow { CustomDivider().padding(.trailing, -24)}
        }
        .foregroundStyle(type == eventType ? Color.accent : Color.black)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { selectType(eventType: eventType)}
    }
    private func selectType(eventType: Event.EventType) {
        if eventType == .custom && message.isEmpty {
            showMessageScreen = true
        }
        type = eventType
        withAnimation(.easeInOut(duration: 0.25)) {
            showTypePopup = false
        }
    }
}
