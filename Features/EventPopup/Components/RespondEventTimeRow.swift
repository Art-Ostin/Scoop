//
//  RespondEventTimeRow.swift
//  Scoop Test
//
//  Created by Art Ostin on 08/09/2026.
//

import SwiftUI


private let iconWidth: CGFloat = 20 //Every icon sits in the same column
private let iconGap: CGFloat = 20 //Icon column ↔ text
private let textColumn = iconWidth + iconGap //Dividers start where the text does
private let rowHeight: CGFloat = 33


//A selectable version of the time row
struct RespondEventTimeRow: View {
    
    private static let platterHeight: CGFloat = 305

    private static let labelTextSize: CGFloat = 17
    private static let labelAnchorInset: CGFloat = (rowHeight - labelTextSize) / 2
    
    @Binding var draft: RespondDraft

    //The container's, not the row's: an open platter dims the CTA, locks the card's drag and hides the title
    @Binding var isOpen: Bool
    
    let bandGround: TimeBandGround?

    //Which screen when it opens -> i.e. is It newTime or original invite
    @State private var page: TimePopupPage? = .newTime

    var body: some View {
        TimeCustomMenu(estimatedContentSize: CGSize(width: TimePopupContainer.invitedWidth, height: Self.platterHeight),
                       tracksContentSizeChanges: true,
                       verticalPlacement: .centred,
                       placementOffsetY: 0,
                       labelAnchorInsetY: Self.labelAnchorInset,
                       isOpen: $isOpen,
                       onOpen: { page = draft.respondType == .newTime ? .newTime : .invitedTimes  },
                       onPlatterFrame: { bandGround?.reportPlatter($0) }) {
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
