//
//  PendingInviteComponents.swift
//  Scoop
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

    private var place: String? {
        let name = FormatEvent.placeName(location)
        return name.isEmpty ? nil : name
    }

    var body: some View {
        if let place {
            Button {
                MapsRouter.openMaps(item: location.mapItem)
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


//The white card a list of invite rows sits in, sized by how many rows it holds
struct InviteListCard<Content: View>: View {

    let rowCount: Int
    @ViewBuilder let content: Content

    //Each row carries Spacing.xs of its own, so the card adds only the remainder
    private var inset: CGFloat {
        Spacing.md - Spacing.xs - (rowCount == 1 ? Spacing.hairline : 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, Spacing.md) //Same as the row's avatar ↔ text gap
        .padding(.vertical, inset)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: .rect(cornerRadius: CornerRadius.md))
    }
}

struct HeaderRow: View {

    //Injected
    let title: String
    var note: String? = nil

    //Local view state
    @State private var showsNote = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.body(18, .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 0)

                if let note {
                    infoButton(note)
                        .padding(.trailing, Spacing.xs)
                }
            }

            if let note {
                RevealingInfoText(text: note, isOpen: showsNote)
            }
        }
    }

    private func infoButton(_ note: String) -> some View {
        Button {
            withAnimation(.expand) { showsNote.toggle() }
        } label: {
            SmallInfoIcon()
                .expandHitArea()
        }
        .growButton()
        .accessibilityLabel(note)
    }
}
