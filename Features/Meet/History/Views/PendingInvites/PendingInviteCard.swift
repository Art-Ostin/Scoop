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
    let showDivider: Bool //False on the last invite of a day — nothing follows it to separate
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
            
            if let image = invite.image {
                SmallImage(image: image, size: Self.avatar, isCircle: true)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HistoryName(name: invite.profile.name)

                Text("\(invite.event.type.longTitle) · \(FormatEvent.hourTime(pending.time.date))")
                    .font(.body(15, .regular))
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            HistoryChevron(isExpanded: isExpanded)
        }
        .padding(.top, Spacing.xs)
        .contentShape(Rectangle()) //PressButtonStyle sets none — without it the row's gaps miss
    }
    
    
    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HistoryPlaceRow(location: invite.event.location)
            HistoryMessageSection(message: invite.event.message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .drawer(isOpen: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
