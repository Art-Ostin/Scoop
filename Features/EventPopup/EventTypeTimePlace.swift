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
        if let respondDraft {
            RespondEventTimeRow(draft: respondDraft)
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
    
    //Updates (1) what event type (2) The original invite selected day (3) A new invites proposed Times
    //Easier to pass in whole draft here
    @Binding var draft: RespondDraft

    @State var isOpen = false
    
    //Which screen when it opens -> i.e. is It newTime or original invite
    @State private var page: TimePopupPage? = .newTime
    
    var body: some View {
        TimeCustomMenu(tracksContentSizeChanges: true, //Both pages reflow: 310↔325 wide, two heights
                       placementOffsetX: 0,
                       placementOffsetY: 24,
                       isOpen: $isOpen,
                       onOpen: { page = .invitedTimes }) {
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
        
    @ViewBuilder
    private var timeText: some View {
        if draft.respondType == .originalInvite {
            if let selectedTime = draft.originalInvite.selectedDay {
                Text(FormatEvent.shortDayAndTime(selectedTime))
            } else {
                Text("Select Time")
            }
        } else if draft.respondType == .newTime {
            Text(draft.newTime.proposedTimes.formatMultipleInvitedDays())
        }
    }
}
