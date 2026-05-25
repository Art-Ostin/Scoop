//
//  EventsScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/05/2026.
//

import SwiftUI

struct EventsScrollView: View {
    
    @Binding var selectedEvent: EventProfile
    
    let events: [EventProfile]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 24) {
                ForEach(events.sorted  ($0.acceptedTime ?? .distantFuture) < ($1.acceptedTime ?? .distantFuture) }) { event in
                    if let date = event.acceptedTime {
                        EventScrollSection(selectedDate: , name: event.otherUserName, date: date)
                    }
                }
            }
        }
    }
}

private struct EventScrollSection: View {
    
    @Binding var selectedEvent: EventProfile
    
    let event: EventProfile
    
    var name: String { event.event.otherUserName}
    var date: Date? { event.event.acceptedTime}
        
    var isSelected: Bool {
        selectedEvent.event.acceptedTime == date
    }
    
    var body: some View {
        
        Button {
            selectedEvent = event
        } label: {
            if let name, let date {
                Text("\(name) · \(formatDate(date))")
                .font(.body(12, .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .stroke(24, lineWidth: 1, color: isSelected ? Color.accent : .black.opacity(0.5))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}

