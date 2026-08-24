//
//  PendingInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI


struct InvitedCard: View {
    
    //Injected
    let pending: PendingInvite
    let showsDivider: Bool //False on the last invite of a day — nothing follows it to separate
    let isExpanded: Bool
    let defaults: DefaultsManaging //Whose maps app the venue opens in
    let onToggle: () -> Void
    
    private static let avatar: CGFloat = 40
    private static let textColumn = avatar + Spacing.md //Geometry: where the text column starts, for what sits under it
    
    private var invite: EventProfile { pending.invite }

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
    
    private var header: some View {
        HStack(spacing: Spacing.md) {
            circlePhoto
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                nameRow
                timeRow
            }
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }
    
    @ViewBuilder
    private var circlePhoto: some View {
        if let image = invite.image {
            SmallImage(image: image, size: Self.avatar, isCircle: true)
        }
    }
    
    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            HistoryName(name: invite.profile.name)
            
            Text("Option \(pending.time.optionNumber)")
                .font(.body(13, .regular))
                .foregroundStyle(Color.textTertiary)
                .fixedSize() //The name truncates, never the label
        }
    }
    
    private var timeRow: some View {
        HStack(spacing: Spacing.md) {
            Text("\(invite.event.type.longTitle) · \(FormatEvent.hourTime(pending.time.date))")
                .font(.body(15, .regular))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HistoryChevron(isExpanded: isExpanded)
        }
    }
}

extension InvitedCard {
    
    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HistoryPlaceRow(location: invite.event.location, defaults: defaults)
            HistoryMessageSection(message: invite.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
