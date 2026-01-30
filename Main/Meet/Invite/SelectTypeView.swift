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
                        customRow(
                            image: eventType.description.emoji ?? "",
                            text: eventType.description.label
                        )
                        .foregroundStyle(selectedType == eventType ? .accent : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        .onTapGesture {
                            let message = (vm.event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            if eventType == .custom && message.isEmpty {
                                vm.showMessageScreen = true
                            }
                            vm.event.type = eventType
                            vm.showTypePopup.toggle()
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
 let hasMessage = (vm.event.message?.isEmpty == false)
 let isCustom = (eventType == .custom)
 
 if isCustom && hasMessage {
     customRow(image: "✒️", text: "Edit Message")
         .foregroundStyle(Color.accent)
         .frame(maxWidth: .infinity)
         .onTapGesture {
             vm.showMessageScreen = true
             vm.event.type = eventType
             vm.showTypePopup.toggle()
         }
 } else
 */



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
