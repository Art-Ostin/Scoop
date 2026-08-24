//
//  PendingInviteComponents.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI

//Structs as used in ExpiredEventCard as well
struct HistoryMessageSection: View {
    
    let message: String?
    var parsedMessage: String? {
        guard let text = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }

    var body: some View {
        if let message = parsedMessage {
            Text(message)
                .font(.body(14, .italic))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(6)
                .padding(.top, Spacing.sm) //Paragraph separation: its own 6pt leading needs more than a line gap
        }
    }
}

struct HistoryPlaceRow: View {
    
    let location: EventLocation
    let defaults: DefaultsManaging
    
    private var place: String? {
        let name = FormatEvent.placeName(location)
        return name.isEmpty ? nil : name
    }
    
    var body: some View {
        if let place {
            Button {
                MapsRouter.openMaps(defaults: defaults, item: location.mapItem)
            } label: {
                Text(place)
                    .font(.body(15, .regular))
                    .foregroundStyle(Color.textAccent)
                    .lineLimit(1)
                    .padding(.top, Spacing.xs)
                    .contentShape(Rectangle())
            }
            .shrinkButton() //Not shrinkPress: its raw DragGesture would claim the scroll's pan
            .instantPressDelivery()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HistoryChevron: View {
    
    let isExpanded: Bool
    
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.icon(12, .semibold))
            .foregroundStyle(Color.textTertiary)
            .rotationEffect(.degrees(isExpanded ? 90 : 0)) //Right → down: opens in place, the app's disclosure idiom
            .animation(.toggle, value: isExpanded)
    }
}

struct HistoryName: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.body(16, .bold))
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
