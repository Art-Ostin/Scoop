//
//  SelectTimeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 29/07/2026.
//

import SwiftUI

//Change the closure for the appropriate time row if respond or send Invite
struct TimeAndPlaceRows<Content: View> : View {
        
    let place: EventLocation
    let proposedTimes: ProposedTimes
    
    @ViewBuilder var selectTimeRow: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            selectTimeRow
            PlaceRow(place: place)
        }
    }
}

struct StaticTimeRow: View {
    let proposedTimes: ProposedTimes
    
    var body: some View {
        LineSection(image: .eventClockIcon, text: proposedTimes.formatMultipleInvitedDays(), textColor: .primary)
            .oneLineLimitAndShrink()
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct DynamicTimeRow: View {
    
    @Binding var draft: RespondDraft
    @Binding var timePopupOpen: Bool
    
    @State private var timePopupPage: TimePopupPage? = .newTime //Must stay at this level
    
    var isInviteCard = false
    
    
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
            LineSection(image: .whiteClock, text: timeText, textColor: .white)
                .padding(.top, -1)
            timeChevron
        }
        .oneLineLimitAndShrink()
    }
    
    private var timeChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.white)
            .rotationEffect(.degrees(timePopupOpen ? 90 : 0))
            .animation(.toggle, value: timePopupOpen)
    }
}


struct PlaceRow: View {
    let place: EventLocation
    
    var body: some View {
        let placeName = place.name ?? place.address ?? "View on map"

        LineSection(image: .eventMapIcon, text: placeName, textColor: .textPrimary)
            .padding(.vertical, Spacing.xs)
            .shrinkPress(action: openMap)
            .padding(.vertical, -Spacing.xs)
            .accessibilityAddTraits(.isButton)
    }

    private func openMap() {
        MapsRouter.openGoogleMaps(item: place.mapItem, withDirections: false)
    }
}


struct LineSection: View {
    let image: ImageResource
    let text: String
    let textColor: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(image)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(textColor)
        }
    }
}
