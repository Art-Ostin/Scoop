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
            RespondEventTimeRow(draft: respondDraft, isOpen: timePopupOpen)
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
        .frame(height: rowHeight)
    }
        
    private var lightDivider: some View {
        VeryLightDivider().padding(.leading, textColumn).blurPop(visible: !covered, scale: 1)
    }

    private var covered: Bool { timePopupOpenDelayed }
}

//A selectable version of the time row
private struct RespondEventTimeRow: View {

    private static let platterHeight: CGFloat = 305

    private static let labelTextSize: CGFloat = 17
    private static let labelAnchorInset: CGFloat = (rowHeight - labelTextSize) / 2
    
    //Updates (1) what event type (2) The original invite selected day (3) A new invites proposed Times
    //Easier to pass in whole draft here
    @Binding var draft: RespondDraft

    //The container's, not the row's: an open platter dims the CTA, locks the card's drag and hides the title
    @Binding var isOpen: Bool
    
    //Which screen when it opens -> i.e. is It newTime or original invite
    @State private var page: TimePopupPage? = .newTime

    var body: some View {
        TimeCustomMenu(estimatedContentSize: CGSize(width: TimePopupContainer.invitedWidth, height: Self.platterHeight),
                       tracksContentSizeChanges: true,
                       verticalPlacement: .centred,
                       placementOffsetY: 0,
                       labelAnchorInsetY: Self.labelAnchorInset,
                       isOpen: $isOpen,
                       onOpen: { page = draft.respondType == .newTime ? .newTime : .invitedTimes  }) {
            popup
        } label: {
            label
        }
    }
    private var popup: some View {
        TimePopupContainer(
            respondType: $draft.respondType,
            selectedDay: $draft.originalInvite.selectedDay,
            newProposedTimes: $draft.newTime.proposedTimes,
            page: $page,
            times: draft.originalInvite.event.proposedTimes
        )
    }
    
    private var label: some View {
         HStack(spacing: iconGap) {
             Image(.eventClockIcon)
                 .scaleEffect(1.2)
                 .frame(width: iconWidth)
             HStack(spacing: 12) {
                 timeText
                 DropDownButton(isOpen: isOpen)
             }
         }
         .frame(height: rowHeight)
         .oneLineLimitAndShrink() //Three named days at 16 bold outrun the row
     }
        
    private var timeText: some View {
        Text(Self.text(for: draft))
            .font(.body(Self.labelTextSize, .bold))
    }

    static func text(for draft: RespondDraft) -> String {
        switch draft.respondType {
        case .originalInvite:
            guard let selectedTime = draft.originalInvite.selectedDay else { return "Select Time" }
            return FormatEvent.shortDayAndTime(selectedTime)
        case .newTime:
            return draft.newTime.proposedTimes.formatMultipleInvitedDays()
        case .newEvent:
            return "" //This row is never the one a new-event draft draws
        }
    }
}
