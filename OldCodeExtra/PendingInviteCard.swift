//
//  PendingInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 23/08/2026.
//

import SwiftUI


struct InvitedCard: View {
    
    //Injected
    let event: EventProfile
    let showDivider: Bool //False on the last invite in the card — nothing follows it to separate
    let isExpanded: Bool
    
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
            
            if showDivider {
                LightDivider()
                    .padding(.vertical, Spacing.xs) //With the row's own, 16 above and 16 below the rule
                    .padding(.leading, Self.textColumn)
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: Spacing.md) {
            
            if let image = event.image {
                SmallImage(image: image, size: Self.avatar, isCircle: true)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HistoryName(name: event.profile.name)
                
                Text(event.event.type.longTitle)
                    .font(.body(13, .regular))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HistoryChevron(isExpanded: isExpanded)
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }
        
    
    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            timeRow
            HistoryPlaceRow(location: event.event.location)
            HistoryMessageSection(message: event.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
    
    //A day that can no longer be accepted fades a step behind the ones still open — the dark
    //days here are exactly the rows the calendar below still draws
    private var timeRow: some View {
        event.event.proposedTimes.invitedDayPieces()
            .map { Text($0.text).foregroundStyle($0.lapsed ? Color.textTertiary : .textSecondary) }
            .reduce(Text(""), +)
            .font(.body(15, .regular))
            .oneLineLimitAndShrink() //Three long days shrink as one line, as the expired row does
            .padding(.top, Spacing.xs) //Type → times: the same step the place row keeps below
    }
}
