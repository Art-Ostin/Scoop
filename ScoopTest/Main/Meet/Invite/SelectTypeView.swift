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
                customRow(image: event.description.emoji, text: event.description.label)
                    .onTapGesture {
                        vm.event.type = event
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
