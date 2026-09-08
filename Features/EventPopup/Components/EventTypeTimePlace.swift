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
    var timePopupOpen: Binding<Bool> = .constant(false) //Goes with `respondDraft`: the container owns the flag — it dims the CTA, locks the card's drag and hides the title
    let actionsBelow: Bool //Adjust spacing if there are actions taken below
    
    var shortSpacing: Bool = false
    var largeText: Bool = false
    let openInfo: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: actionsBelow ? shortSpacing ? 12 : 14 : 19) {
            typeRow
                .opacity(coveredOpacity)
            lightDivider
            timeRow
            lightDivider
            iconRow(.eventMapIcon, invite.place.name ?? "View Venue")
                .opacity(coveredOpacity)
        }
        .animation(.transition, value: timePopupOpen.wrappedValue)
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
        VeryLightDivider().padding(.leading, textColumn).opacity(coveredOpacity)
    }

    //Everything the card shows around an open time platter fades with it. The place row's pin sits left of
    //the narrower platter and the dividers run out both sides — those are spill. The type row is not: the
    //platter hugs its content now, and `.above` pins its BOTTOM, so its top edge sits below that row. It
    //fades for focus, so the open platter is read against the photo rather than a half-lit card.
    //FADED, never removed: the platter is anchored to the time row's frame, and reflowing the card under an
    //open menu would move that anchor. The TIME row is deliberately absent from this — it IS the menu's
    //label, hidden by `hidesLabel` on the exact frame the lens takes its place ("overlap, never a gap"),
    //and a second fade keyed on `timePopupOpen` would pull it a frame early on the way in and fight the
    //droplet close, which morphs back into it, on the way out.
    private var coveredOpacity: Double { timePopupOpen.wrappedValue ? 0 : 1 }
}

//A selectable version of the time row
private struct RespondEventTimeRow: View {

    //Geometry: a seed for the very FIRST bloom only, before any measurement exists — roughly the invited
    //page, which is the page every open lands on. It no longer feeds the centring (`.centred` reads the
    //measured height instead), and `tracksContentSizeChanges` corrects it within a frame, so being a little
    //tall for a short invite costs nothing.
    private static let platterHeight: CGFloat = 305
    
    //Updates (1) what event type (2) The original invite selected day (3) A new invites proposed Times
    //Easier to pass in whole draft here
    @Binding var draft: RespondDraft

    //The container's, not the row's: an open platter dims the CTA, locks the card's drag and hides the title
    @Binding var isOpen: Bool
    
    //Which screen when it opens -> i.e. is It newTime or original invite
    @State private var page: TimePopupPage? = .newTime
    
    var body: some View {
        TimeCustomMenu(estimatedContentSize: CGSize(width: TimePopupContainer.invitedWidth, height: Self.platterHeight),
                       tracksContentSizeChanges: true, //Each page wears its own platter — narrower on the invited page, and hugging its own content — so both axes reflow. Off, the sizer only mounts while `cachedMenuSize` is nil, so the first open's size would freeze for the session
                       verticalPlacement: .centred, //The menu reads the measured height and wears the row through its middle. An offset constant could only be right at ONE height, and neither page is that height now
                       placementOffsetY: 0, //`.centred` needs no nudge, and the parameter's default is not zero
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
        
    private var timeText: some View {
        Group {
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
        .font(.body(17, .bold))
    }
}
