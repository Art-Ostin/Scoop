//
//  EventsScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/05/2026.
//




import SwiftUI

struct EventsScrollView: View {

    @Binding var selectedEvent: EventProfile?

    let events: [EventProfile]

    private var sortedEvents: [(event: EventProfile, date: Date)] {
        events
            .compactMap { profile in profile.event.acceptedTime.map { (profile, $0) } }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ClearRectangle(size: 0)
                ForEach(sortedEvents, id: \.event.id) { item in
                    EventScrollSection(selectedEvent: $selectedEvent, event: item.event, date: item.date)
                        .padding(.trailing, 8)
                }
                ClearRectangle(size: 0)
            }
        }
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: true)
        .customHorizontalScrollFade(width: 24, showFade: true, fromLeading: false)
    }
}

private struct EventScrollSection: View {

    @Binding var selectedEvent: EventProfile?

    let event: EventProfile
    let date: Date

    var name: String { event.event.otherUserName }

    var isSelected: Bool {
        selectedEvent?.id == event.id
    }

    var body: some View {
        Button {
            selectedEvent = event
        } label: {
            Text("\(name) · \(formatDate(date))")
                .font(.body(12, isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.3, green: 0.3, blue: 0.3))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .stroke(24, lineWidth: 1, color: isSelected ? Color.accent : Color(red: 0.4, green: 0.4, blue: 0.4))
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}
