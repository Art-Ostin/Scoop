//
//  InviteTimeAndPlaceRow.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2026.
//

import SwiftUI

private let chevronSpacing: CGFloat = 9
private let rowHeight: CGFloat = 33

struct InviteTimeRow: View {
    //Injected data updating
    @Binding var proposedTimes: ProposedTimes
    
    //If time is open
    @Binding var timeisOpen: Bool
    let typePopUpOpen: Bool
    
    var body: some View {
        HStack {
            RowCaption(label: .when)
            Spacer(minLength: 12)
            TimeCustomMenu(
                estimatedContentSize: CGSize(width: SelectTimeView.platterWidth, height: 307),
                verticalPlacement: .below,
                isOpen: $timeisOpen,
                content: {SelectTimeView(proposedTimes: $proposedTimes).frame(width: SelectTimeView.platterWidth)},
                label: {rowLabel}
            )
        }
        .frame(minHeight: rowHeight + (proposedTimes.dates.count > 2 ? 6 : 0))//Make it tad taller if time beaneath it
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
    static let size: CGFloat = 17 //shared with the type row, whose open caption grows to meet it

    let text: String
    var body: some View {
        Text(text)
            .font(.body(Self.size, .medium))
            .foregroundStyle(Color.textPrimary)
    }
}

struct RowCaption: View {
    enum Label: String {
        case what, when, `where`
        var text: String { rawValue.capitalized }
    }

    static let size: CGFloat = 13 //shared with the type row's grown twin, so its scale is exact

    let label: Label
    
    var body: some View {
        Text(label.text)
            .font(.body(Self.size, .medium))
            .foregroundStyle(Color.textTertiary)
    }
}

struct DropDownButton: View {
    static let width: CGFloat = 6 //pinned so rows can lay out against it; shared with the type row's morph box

    let isOpen: Bool
    
    var body: some View {
        Image("DropdownGray")
            .rotationEffect(.degrees(isOpen ? 90 : 0))
            .animation(.toggle, value: isOpen)
            .frame(width: Self.width)//So always predictable
    }
}
