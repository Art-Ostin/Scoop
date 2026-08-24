//
//  ExpiredEventCard.swift
//  Scoop
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI

struct ExpiredEventCard: View {

    //Injected
    let event: EventProfile
    let showsDivider: Bool //False on the last expired invite — nothing follows it to separate
    let isExpanded: Bool
    let defaults: DefaultsManaging //Whose maps app the venue opens in
    let onToggle: () -> Void

    private static let avatar: CGFloat = 40
    private static let textColumn = avatar + Spacing.md //Geometry: where the text column starts, for what sits under it

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onToggle()
            } label: {
                header
            }
            .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
            .instantPressDelivery()

            expandedDetail
                .padding(.leading, Self.textColumn)
                .padding(.bottom, Spacing.xs) //The row's own half of the gap; the rule below adds the rest

            if showsDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
                    .padding(.leading, Self.textColumn)
            }
        }
    }
}

//The tappable header and the drawer of days, place, and message it opens
extension ExpiredEventCard {

    //The greedy name column pushes the chevron trailing; it centers on both lines, as the row opens as a whole
    private var header: some View {
        HStack(spacing: Spacing.md) {
            circlePhoto

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HistoryName(name: event.profile.name)
                typeRow
            }

            HistoryChevron(isExpanded: isExpanded)
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }

    //The type takes the name's second line — the days list below needs a full-width line of its own
    private var typeRow: some View {
        Text("\(event.event.type.longTitle) · \(lastTime)")
            .font(.body(13, .regular))
            .foregroundStyle(Color.textTertiary)
            .lineLimit(1)
    }

    //Every day the invite offered, on one line — the same string the confirm card's time row shows
    private var timesRow: some View {
        Text(event.event.proposedTimes.formatMultipleInvitedDays())
            .font(.body(15, .regular))
            .foregroundStyle(Color.textSecondary)
            .oneLineLimitAndShrink() //Three days runs long; shrink rather than truncate, as the confirm row does
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xs) //Type → times: the same step the place row keeps below
    }
    
    private var lastTime: String {
        let date = event.event.proposedTimes.lastProposedDate
        return FormatEvent.shortDayAndTime(date, withHour: false, withToday: true)
    }

    @ViewBuilder
    private var circlePhoto: some View {
        if let image = event.image {
            SmallImage(image: image, size: Self.avatar, isCircle: true)
        }
    }

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            timesRow
            HistoryPlaceRow(location: event.event.location, defaults: defaults)
            HistoryMessageSection(message: event.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
