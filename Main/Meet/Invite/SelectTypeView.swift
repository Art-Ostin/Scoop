//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct SelectTypeView: View {
    
    @Bindable var vm: TimeAndPlaceViewModel   // if your VM is @Observable
    // If your VM is not @Observable, tell me what it is (ObservableObject?), and I’ll adjust.
    
    let selectedType: EventType?
    
    
    var body: some View {
        VStack(spacing: 0) {
            DropDownMenu {
                ForEach(Array(EventType.allCases.enumerated()), id: \.element) { index, eventType in
                    
                    let hasMessage = (vm.event.message?.isEmpty == false)
                    let isCustom = (eventType == .custom)
                    
                    if isCustom && hasMessage {
                        customRow(image: "✒️", text: "Edit Message")
                            .foregroundStyle(Color.accent)
                            .onTapGesture {
                                vm.showMessageScreen = true
                                vm.event.type = eventType
                                vm.showTypePopup.toggle()
                            }
                    } else {
                        customRow(
                            image: eventType.description.emoji ?? "",
                            text: eventType.description.label
                        )
                        .font(.body)
                        .fontWeight(selectedType == eventType ? .bold : .medium)
                        
                        
                        .onTapGesture {
                            if isCustom { vm.showMessageScreen = true }
                            vm.event.type = eventType
                            vm.showTypePopup.toggle()
                        }
                    }
                    if index < EventType.allCases.count - 1 {
                        SoftDivider()
                    }
                }
            }
        }
    }
}



/*
 
 
 
 
 
}


ForEach(Array(EventType.allCases), id: \.self) { event in
 if event == .custom && vm.event.message != nil {
     customRow(image: "✒️", text: "Edit Message")
         .foregroundStyle(Color.accent)
         .onTapGesture {
             if event == .custom {
                 vm.showMessageScreen = true
             }
             vm.event.type = event
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 vm.showTypePopup.toggle()
             }
         }
 } else {
     customRow(image: event.description.emoji, text: event.description.label)
         .onTapGesture {
             if event == .writeAMessage {
                 vm.showMessageScreen = true
             }
             vm.event.type = event
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 vm.showTypePopup.toggle()
             }
         }
     if event != EventType.allCases.last {
         SoftDivider()
     }
 }
 */
