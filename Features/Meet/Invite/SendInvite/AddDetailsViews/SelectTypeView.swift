//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel
    @Bindable var ui: TimeAndPlaceUIState

    let selectedType: Event.EventType?
    @Binding var showTypePopup: Bool
    
    var body: some View {
        DropDownMenu {
            ForEach(Event.EventType.allCases, id: \.self) {eventType in
                DropDownRow(
                    image: eventType.description.emoji,
                    text: eventType.description.label,
                    isSelected: selectedType == eventType,
                    isLastRow: eventType == Event.EventType.allCases.last
                ) {
                    selectType(eventType: eventType)
                }
            }
        }
    }
    private func selectType(eventType: Event.EventType) {
        let message = (vm.event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if eventType == .custom && message.isEmpty {
            ui.showMessageScreen = true
        }
        vm.event.type = eventType
        withAnimation(.easeInOut(duration: 0.25)) {
            showTypePopup.toggle()
        }
    }
}



/*
 
 DropDownRow(
     image: eventType.description.emoji ?? "",
     text: eventType.description.label
 )
 .foregroundStyle(selectedType == eventType ? .accent : .black)
 .onTapGesture {
     let message = (vm.event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
     if eventType == .custom && message.isEmpty {
         ui.showMessageScreen = true
     }
     vm.event.type = eventType
     withAnimation(.easeInOut(duration: 0.25)) {
         showTypePopup.toggle()
     }
 }

 */
