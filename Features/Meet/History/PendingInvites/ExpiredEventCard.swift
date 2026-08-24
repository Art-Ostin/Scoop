//
//  ExpiredEventCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI

struct ExpiredEventCard: View {
    
    let event: EventProfile
    let isExpanded: Bool
    let showsDivider: Bool
    let defaults: DefaultsManaging
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
            
            expandDetail
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

extension ExpiredEventCard {
    
    private var header: some View {
        HStack(spacing: Spacing.md) {
            circlePhoto
            
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    nameRow
                    timesRow
                }

                Spacer()
                
                HistoryChevron(isExpanded: isExpanded)
            }
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }
    
    //The type rides the trailing slot a pending card gives "Option n" — the days need the whole line below
    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            HistoryName(name: event.profile.name)

            Text(event.event.type.longTitle)
                .font(.body(13, .regular))
                .foregroundStyle(Color.textTertiary)
                .fixedSize() //The name truncates, never the label
        }
    }

    //Every day the invite offered, on one line — the same string the confirm card's time row shows
    private var timesRow: some View {
        Text(event.event.proposedTimes.formatInvitedDaysList())
            .font(.body(15, .regular))
            .foregroundStyle(Color.textSecondary)
            .oneLineLimitAndShrink() //Three days runs long; shrink rather than truncate, as the confirm row does
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var circlePhoto: some View {
        if let image = event.image {
            SmallImage(image: image, size: Self.avatar, isCircle: true)
        }
    }
    
    @ViewBuilder
    private var expandDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HistoryPlaceRow(location: event.event.location, defaults: defaults)
            HistoryMessageSection(message: event.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
