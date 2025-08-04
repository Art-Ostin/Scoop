//
//  SelectTypeView.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI


struct SelectTypeView: View {
    
    @Binding var vm: SendInviteViewModel
    
    var body: some View {

        DropDownMenu {
            ForEach(EventType.allCases, id: \.self) {event in
                if event == .writeAMessage && vm.event.message != nil { customRow(image: "✒️", text: "Edit Message")
                        .foregroundStyle(Color.accent)
                        .onTapGesture {
                            if event == .writeAMessage {
                                vm.showMessageScreen = true
                            }
                            vm.event.type = event.description.label
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                vm.showTypePopup.toggle()
                            }
                        }
                }
                else {
                    customRow(image: event.description.emoji, text: event.description.label)
                        .onTapGesture {
                            if event == .writeAMessage {
                                vm.showMessageScreen = true
                            }
                            vm.event.type = event.description.label
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                vm.showTypePopup.toggle()
                            }
                        }
                     
                    if event != EventType.allCases.last {
                        SoftDivider()
                    }
                }
            }
        }
    }
}
