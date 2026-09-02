//
//  EventTypeTimePlace.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

private let iconWidth: CGFloat = 20 //Every icon sits in the same column
private let iconGap: CGFloat = 20 //Icon column ↔ text
private let textColumn = iconWidth + iconGap //Dividers start where the text does
private let rowHeight: CGFloat = 33


struct EventTypeTimePlace: View {
    let invite: InviteSummary
    var times: Binding<ProposedTimes>? //Only responding to an event needs a binding
    let actionsBelow: Bool //Adjust spacing if there are actions taken below
    let openInfo: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: actionsBelow ? 14 : 19) {
            typeRow
            lightDivider
            timeRow
            lightDivider
            iconRow(.eventMapIcon, invite.place.name ?? "View Venue")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, actionsBelow ? Spacing.md : Spacing.lg - Spacing.xxs) //Alone, a nudge less than the sides
        .padding(.bottom, actionsBelow ? 0 : Spacing.lg)
    }
}

extension EventTypeTimePlace {
    private var typeRow: some View {
        HStack(spacing: iconGap) {
            Text(invite.type.emoji)
                .font(.body(16, .bold))
                .frame(width: iconWidth)

            VStack(alignment: .leading, spacing: 6) {
                Button(action: openInfo) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text(invite.type.longTitle).font(.body(16, .bold))
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.textTertiary)
                            .font(.body(11, .medium))
                            .offset(x: -8, y: -2) //Geometry: nudged in toward the title
                    }
                }
                .growButton()

                if let message = invite.message {
                    Text(message)
                        .font(.body(14, .regularItalic))
                        .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
                        .lineLimitAndShrink(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(minHeight: rowHeight) //Grows past the one-line row box when a message is present
    }
    
    @ViewBuilder
    var timeRow: some View {
        if let times {
            RespondEventTimeRow(proposedTimes: times)
        } else {
            iconRow(.eventClockIcon, invite.time.formatMultipleInvitedDays())
        }
    }

    private func iconRow(_ icon: ImageResource, _ text: String) -> some View {
        HStack(spacing: iconGap) {
            Image(icon)
                .scaleEffect(1.2)
                .frame(width: iconWidth)
            Text(text).font(.body(16, .bold))
        }
        .frame(height: rowHeight)
    }
        
    private var lightDivider: some View {
        VeryLightDivider().padding(.leading, textColumn)
    }
}

//A selectable version of the time row
private struct RespondEventTimeRow: View {
    @Binding var proposedTimes: ProposedTimes
    var body: some View { }
}
