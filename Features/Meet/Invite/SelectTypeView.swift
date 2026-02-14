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
    
    @Binding var showTypePopup: Bool
    
    
    var body: some View {
        VStack(spacing: 0) {
            DropDownMenu {
                ForEach(Array(EventType.allCases.enumerated()), id: \.element) { index, eventType in
                        customRow(
                            image: eventType.description.emoji ?? "",
                            text: eventType.description.label
                        )
                        .foregroundStyle(selectedType == eventType ? .accent : .black)
                        .onTapGesture {
                            let message = (vm.event.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            if eventType == .custom && message.isEmpty {
                                vm.showMessageScreen = true
                            }
                            vm.event.type = eventType
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showTypePopup.toggle()
                            }
                        }
                    if index < EventType.allCases.count - 1 {
                        MapDivider()
                    }
                }
                
            }
        }
    }
}
