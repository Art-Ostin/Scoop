//
//  InviteTypeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

private let chevronSpacing: CGFloat = 9
private let rowHeight: CGFloat = 33

struct InviteTypeRow: View {
    
    //Injected Data to updated
    @Binding var eventType: Event.EventType
    @Binding var message: String?
    
    //Injected UI updating
    @Binding var showMessageScreen: Bool
    @Binding var showInfoScreen: Bool
    @Binding var showTypeDropDown: Bool
    
    //Hide the row when timeDropDown is open
    let timePopupOpen: Bool
    
    //Store which 'info' icons for the selectTypeDowndown open
    @State private var openInfoTypes: Set<Event.EventType> = []
    
    var body: some View {
        //Baseline, not top edge: the 13pt caption sits on the 17pt title's line, and a message grows beneath it
        HStack(alignment: .firstTextBaseline) {
            RowCaption(label: .what)
                .overlay(alignment: .topTrailing) {infoIcon}
            Spacer(minLength: 12)
            DropdownCustomMenu(
                isOpen: $showTypeDropDown,
                showMessageScreen: $showMessageScreen,
                message: message ?? "",
                onClose: { openInfoTypes.removeAll() },
                content: { selectTypeView },
                label:   { rowLabel }
            )
        }
        .frame(minHeight: rowHeight) //Grows past the one-line row box when a message is present
    }
    
    private var rowLabel: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: chevronSpacing) {
                EventRowText(text: eventType.longTitle)
                DropDownButton(isOpen: showTypeDropDown)
            }
            if let visibleMessage { eventMessage(text: visibleMessage) }
        }
    }
    
    private var visibleMessage: String? {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return message
    }
    
    private func eventMessage(text: String) -> some View {
        Text(text)
            .font(.body(14, .regularItalic))
            .foregroundStyle(Color.textSecondary.opacity(0.7)) //Tad lighter than normal secondary
            .lineLimitAndShrink(3)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, chevronSpacing + 6)//Chevron is 6 points wide. Don't Change!!
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.trailing)
    }
    
    //The type view I open up
    private var selectTypeView: some View {
        SelectTypeView(
            openTypes: $openInfoTypes,
            selectedType: $eventType,
            showMessageScreen: $showMessageScreen,
            message: message ?? ""
        )
    }
    
    private var infoIcon: some View {
        Button {
            showInfoScreen = true
        } label: {
            SmallInfoIcon()
                .scaleEffect(0.8)
                .offset(x: 14, y: -3)
        }
    }
}

struct InviteTimeRow: View {
    //Injected data updating
    @Binding var proposedTimes: ProposedTimes
    
    //If time is open
    @Binding var timeisOpen: Bool
    let typePopUpOpen: Bool
    
    let menuWidth: CGFloat = 325 //The platter width: the day grid's 274pt fits the 277pt column it leaves
    
    var body: some View {
        HStack {
            RowCaption(label: .when)
            Spacer(minLength: 12)
            TimeCustomMenu(
                estimatedContentSize: CGSize(width: menuWidth, height: 286),
                verticalPlacement: .below,
                isOpen: $timeisOpen,
                content: {SelectTimeView(proposedTimes: $proposedTimes).frame(width: menuWidth)},
                label: {rowLabel}
            )
        }
        .frame(minHeight: rowHeight)
        .blurPop(visible: !typePopUpOpen, scale: 1)
    }
    
    private var rowLabel: some View {
        HStack(spacing: chevronSpacing) {
            if proposedTimes.dates.isEmpty {
                EventRowPlaceholder(text: "Choose Time")
            } else {
                eventRowText
            }
            DropDownButton(isOpen: timeisOpen == true)
        }
    }
    
    private var eventRowText: some View {
        let isThreeDays = proposedTimes.dates.count > 2
        return VStack(alignment: .trailing, spacing: 5) {
            EventRowText(text: proposedTimes.formatMultipleInvitedDays(withHour: !isThreeDays))
            if isThreeDays {
                if let day = proposedTimes.dates.first {
                    Text(FormatEvent.hourTime(day.date))
                        .font(.body(11, .bold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

struct InvitePlaceRow: View {
    let popupOpen: Bool
    @Binding var location: EventLocation?
    @Binding var showMapView: Bool
    
    var body: some View {
        HStack {
            RowCaption(label: .where)
            Spacer()
            HStack(spacing: chevronSpacing) {
                if let location {
                    eventText(location)
                } else {
                   EventRowPlaceholder(text: "Choose Place")
                }
                DropDownButton(isOpen: false)
            }
            .shrinkPress { showMapView = true }
        }
        .frame(minHeight: rowHeight)
        .blurPop(visible: !popupOpen, scale: 1)
    }
    
    private func eventText(_ location: EventLocation) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            EventRowText(text: location.name ?? "The Venue")
            Text(FormatEvent.addressBeforeFirstComma(location.address))
                .font(.body(12, .regular))
                .foregroundStyle(Color.textPlaceholder)
                .lineLimit(1)
        }
    }
}

//Generic Components
struct EventRowPlaceholder: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body(16, .regular))
            .foregroundStyle(Color.textSecondary)
            .kerning(text == "Choose Time" ? 0.32 : 0)
    }
}

struct EventRowText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body(17, .medium))
            .foregroundStyle(Color.textPrimary)
    }
}

struct RowCaption: View {
    enum Label: String { case what, when, `where` }

    let label: Label
    
    var body: some View {
        Text(label.rawValue.capitalized)
            .font(.body(13, .medium))
            .foregroundStyle(Color.textTertiary)
    }
}

struct DropDownButton: View {
    let isOpen: Bool
    
    var body: some View {
        Image("DropdownGray")
            .rotationEffect(.degrees(isOpen ? 90 : 0))
            .animation(.toggle, value: isOpen)
            .frame(width: 6)//So always predictable
    }
}
