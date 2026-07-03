//
//  EventScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 11/06/2026.
//

import SwiftUI

struct EventScrollView: View {
    
    @Binding var selectedEvent: String?
    @Bindable var vm: EventsViewModel
    
    var body: some View {
        ForEach(vm.events) { event in
            let isSelected = selectedEvent == event.id
            
            ScoopButton(style: .clearGlass, shape: .capsule) {
                selectedEvent = event.id
            } label: {
                Text(eventFormatter(event: event))
                    .font(.body(12, .bold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .inset(by: 0.5)
                            .stroke(Color.textAccent, lineWidth: 1)
                    )
                    .animation(.spring, value: isSelected)
            }
        }
    }
    
    private func eventFormatter(event: EventProfile) -> String {
        let name = event.profile.name

        guard let date = event.event.acceptedTime else {
            return name
        }

        let month = date.formatted(.dateTime.month(.abbreviated))
        let monthDay = date.formatted(.dateTime.day(.defaultDigits))

        return "\(name) · \(monthDay) \(month)"
    }
}
