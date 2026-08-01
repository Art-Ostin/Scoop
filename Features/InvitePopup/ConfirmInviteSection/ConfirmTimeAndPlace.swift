//
//  ConfirmTimeAndPlace.swift
//  Scoop
//
//  Created by Art Ostin on 29/07/2026.
//

import SwiftUI

//Change the closure for the appropriate time row if respond or send Invite
struct TimeAndPlaceRows<TimeRow: View> : View {

    let place: EventLocation
    let style: ConfirmStyle
    var timeOpen: Bool = false

    @ViewBuilder var timeRow: TimeRow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            timeRow
                .opacityPop(visible: !timeOpen)
            PlaceRow(place: place, style: style)
                .opacityPop(visible: !timeOpen)
        }
        .font(.body(18, .medium))
        .fixedSize(horizontal: false, vertical: true)   //pin single-line rows to natural height
        .padding(.horizontal, Spacing.margin)
        .padding(.bottom, style.rowsBottomPadding)
        .containerRelativeFrame(.horizontal, alignment: .leading)
    }
}

struct StaticTimeRow: View {
    let proposedTimes: ProposedTimes
    
    var body: some View {
        LineSection(image: .eventClockIcon, text: proposedTimes.formatMultipleInvitedDays())
            .oneLineLimitAndShrink()
    }
}


struct DynamicTimeRow: View {
    
    @Binding var draft: RespondDraft
    @Binding var timePopupOpen: Bool
    
    @State private var timePopupPage: TimePopupPage? = .newTime //Must stay at this level

    let style: ConfirmStyle


    var body: some View {
        TimeCustomMenu(cornerRadius: CornerRadius.customMenu,
                       tracksContentSizeChanges: true,
                       placementOffsetX: 0,
                       placementOffsetY: 24,
                       isOpen: $timePopupOpen,
                       onOpen: { timePopupPage = .invitedTimes }) {
            timePopupContainer
        } label: {
            timeRow
        }
    }
    
    private var timeText: String {
        if draft.respondType == .originalInvite {
            if let time = draft.originalInvite.selectedDay {
                return FormatEvent.shortDayAndTime(time)
            } else {
                return "Choose Time"
            }
        } else if draft.respondType == .newTime {
           return draft.newTime.proposedTimes.formatMultipleInvitedDays()
        } else {
            return ""
        }
    }
    
    
    private var timePopupContainer: some View {
        TimePopupContainer(
            respondType: $draft.respondType,
            selectedDay: $draft.originalInvite.selectedDay,
            newProposedTimes: $draft.newTime.proposedTimes,
            page: $timePopupPage,
            times: draft.originalInvite.event.proposedTimes
        )
    }
    
    private var timeRow: some View {
        HStack {
            LineSection(image: style.clockIcon, text: timeText)
                .padding(.top, -1)
            timeChevron
        }
        .oneLineLimitAndShrink()
    }
    
    private var timeChevron: some View {
        Image(systemName: "chevron.right")
            .font(.body(12, .bold))
            .rotationEffect(.degrees(timePopupOpen ? 90 : 0))
            .animation(.toggle, value: timePopupOpen)
            .offset(y: -2)
    }
}


struct PlaceRow: View {
    let place: EventLocation
    let style: ConfirmStyle

    var body: some View {
        let placeName = place.name ?? place.address ?? "View on map"
        LineSection(image: style.mapIcon, text: placeName)
            .padding(.vertical, Spacing.xs)
            .shrinkPress(action: openMap)
            .padding(.vertical, -Spacing.xs)
            .accessibilityAddTraits(.isButton)
    }

    private func openMap() {
        MapsRouter.openGoogleMaps(item: place.mapItem, withDirections: false)
    }
}

//Colour and font are inherited — the host sets them once for the whole section.
struct LineSection: View {
    let image: ImageResource
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(image)
                .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to

            Text(text)
        }
    }
}
