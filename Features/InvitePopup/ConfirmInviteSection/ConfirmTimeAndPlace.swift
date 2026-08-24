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

    //The quick-invite flight's destination anchor for the place row (nil outside a flight)
    var placeRowFrame: Binding<CGRect>? = nil

    @ViewBuilder var timeRow: TimeRow

    //While the flight's hero rows own the time and place they never render here (ghosts keep
    //the layout); at rest this is identity
    @Environment(\.inviteRowsFlying) private var rowsFlying
    @Environment(\.inviteChromeFade) private var chromeFade

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            timeRow
                .blurPop(visible: !timeOpen, scale: 1)
            PlaceRow(place: place, style: style)
                .blurPop(visible: !timeOpen, scale: 1)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { placeRowFrame?.wrappedValue = $0 }
        }
        .opacity(rowsFlying ? 0 : chromeFade) //Heroes own the rows; a hero-less flight rushes them out with the scrim
        .font(.body(style.timeAndPlaceSizing, .medium))
        .kerning(0.1)
        .fixedSize(horizontal: false, vertical: true)   //pin single-line rows to natural height
        .padding(.horizontal, Spacing.margin)
        .padding(.bottom, style.rowsBottomPadding)
        .containerRelativeFrame(.horizontal, alignment: .leading)
    }
}

struct StaticTimeRow: View {
    let proposedTimes: ProposedTimes
    let style: ConfirmStyle
    
    var body: some View {
        LineSection(image: .eventClockIcon, text: proposedTimes.formatMultipleInvitedDays(), style: style)
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
                       platterFill: style.timePopupFill,
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
    
    private var timeText: String { Self.text(for: draft) }

    //Static so the quick-invite flight's hero row can render the exact string this row shows
    static func text(for draft: RespondDraft) -> String {
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
            LineSection(image: style.clockIcon, text: timeText, style: style)
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
        Button(action: openMap) {
            LineSection(image: style.mapIcon, text: placeName, style: style)
                .padding(.vertical, Spacing.xs)
                .padding(.trailing, style == .card ? 72 : 0) //On Card add trailing padding as Invite Button is an overlay
                .oneLineLimitAndShrink(minimum: 0.8)
        }
        .shrinkButton()
        .padding(.vertical, -Spacing.xs)
        .oneLineLimitAndShrink()
    }

    private func openMap() {
        MapsRouter.openGoogleMaps(item: place.mapItem, withDirections: false)
    }
}

//Colour and font are inherited — the host sets them once for the whole section.
struct LineSection: View {
    let image: ImageResource
    let text: String
    let style: ConfirmStyle
    
    
    var body: some View {
        HStack(spacing: style.iconRowSpacing) {
            Image(image)
                .renderingMode(style.iconRendering)
                .frame(width: 20, alignment: .leading) //Geometry: icon column both rows align to

            Text(text)
        }
    }
}
