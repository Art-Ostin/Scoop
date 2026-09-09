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
    var respondDraft: Binding<RespondDraft>? //Only responding to an event needs a binding
    var timePopupOpen: Binding<Bool> = .constant(false)
    var timePopupOpenDelayed: Bool = false
    let actionsBelow: Bool //Adjust spacing if there are actions taken below
    
    var shortSpacing: Bool = false
    var largeText: Bool = false
    var heroLanding: Bool = false
    var bandGround: TimeBandGround? = nil //Where this row's platter reports the frame its band must meet
    let openInfo: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: actionsBelow ? shortSpacing ? 12 : 14 : 19) {
            typeRow
                .blurPop(visible: !covered, scale: 1)
            lightDivider
            timeRow
                .eventZoomRowTarget(.time, text: timeRowText, active: heroLanding)
            lightDivider
            iconRow(.eventMapIcon, placeName)
                .eventZoomRowTarget(.place, text: placeName, active: heroLanding)
                .blurPop(visible: !covered, scale: 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, actionsBelow ? Spacing.md : Spacing.lg - Spacing.xxs) //Alone, a nudge less than the sides
        .padding(.bottom, actionsBelow ? 14 : Spacing.lg)
    }
}

//Type row
extension EventTypeTimePlace {
    
    private var typeRow: some View {
        HStack(spacing: iconGap) {
            Text(invite.type.emoji)
                .font(.body(16, .bold))
                .frame(width: iconWidth)

            VStack(alignment: .leading, spacing: 4) {
                eventTitleAndInfo
                if let message = invite.message, !message.isEmpty {
                    eventMessage(message: message)
                }
            }
        }
        .frame(minHeight: rowHeight) //Grows past the one-line row box when a message is present
    }
    
    private func eventMessage(message: String) -> some View {
        Text(message)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var eventTitleAndInfo: some View {
        Button(action: openInfo) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Text(invite.type.longTitle).font(.body(largeText ? 17 : 16, .bold))
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.textTertiary)
                    .font(.body(11, .medium))
                    .offset(x: -8, y: -2) //Geometry: nudged in toward the title
            }
        }
        .growButton()
    }
}

//Time And Place Row
extension EventTypeTimePlace {
    
    @ViewBuilder
    var timeRow: some View {
        if let respondDraft {
            RespondEventTimeRow(draft: respondDraft, isOpen: timePopupOpen, bandGround: bandGround)
        } else {
            iconRow(.eventClockIcon, invite.time.formatMultipleInvitedDays())
        }
    }

    //Hoisted so the drawn rows and the strings the event zoom flies onto them can never disagree —
    //a hero that lands spelling something else hands off with a visible word change
    var placeName: String { invite.place.name ?? "View Venue" }

    var timeRowText: String {
        guard let respondDraft else { return invite.time.formatMultipleInvitedDays() }
        return RespondEventTimeRow.text(for: respondDraft.wrappedValue)
    }

    private func iconRow(_ icon: ImageResource, _ text: String) -> some View {
        HStack(spacing: iconGap) {
            Image(icon)
                .scaleEffect(1.2)
                .frame(width: iconWidth)
            Text(text).font(.body(largeText ? 17 : 16, .bold))
        }
        .lineLimit(1)
        .frame(height: rowHeight)
    }
        
    private var lightDivider: some View {
        VeryLightDivider().padding(.leading, textColumn).blurPop(visible: !covered, scale: 1)
    }

    private var covered: Bool { timePopupOpenDelayed }
}

