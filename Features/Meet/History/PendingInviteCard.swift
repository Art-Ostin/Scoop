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
    let showsChevron: Bool //False while another day's card for this same invite is open
    let defaults: DefaultsManaging //Whose maps app the venue opens in
    let onToggle: () -> Void
    
    //Local view state
    @State private var detailHeight: CGFloat = 0
    
    private static let avatar: CGFloat = 40
    private static let textColumn = avatar + Spacing.md //Geometry: where the text column starts, for what sits under it
    
    private var invite: EventProfile { pending.invite }
    
    private var message: String? {
        guard let text = invite.event.message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }
    
    private var place: String? {
        let name = FormatEvent.placeName(invite.event.location)
        return name.isEmpty ? nil : name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onToggle()
            } label: {
                header
            }
            .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
            .instantPressDelivery()
            
            //Outside the Button, never inside its label: a label is content, so a venue nested
            //there could not take its own tap — and the row would shrink for a press meant for Maps
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
        } else {
            Circle()
                .fill(Color.fillGray)
                .frame(width: Self.avatar, height: Self.avatar)
        }
    }
    
    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            Text(invite.profile.name)
                .font(.body(16, .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
            
            chevronSlot
        }
    }
    
    private var chevronSlot: some View {
        Image(systemName: "chevron.right")
            .font(.icon(12, .semibold))
            .foregroundStyle(Color.textTertiary)
            .rotationEffect(.degrees(isExpanded ? 90 : 0)) //Right → down: opens in place, the app's disclosure idiom
            .animation(.toggle, value: isExpanded)
            .opacity(showsChevron ? 1 : 0)
            .blur(radius: showsChevron ? 0 : 6) //the .blurReplace look, without leaving layout
            .animation(.transition, value: showsChevron)
    }
}

extension InvitedCard {
    
    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            placeRow
            messageSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .getHeight($detailHeight)
        .frame(height: isExpanded ? detailHeight : 0, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
    
    @ViewBuilder
    private var placeRow: some View {
        if let place {
            Button {
                MapsRouter.openMaps(defaults: defaults,
                                    item: invite.event.location.mapItem,
                                    withDirections: false)
            } label: {
                Text(place)
                    .font(.body(15, .regular))
                    .foregroundStyle(Color.textAccent)
                    .lineLimit(1)
                    .padding(.top, Spacing.xs)
                    .contentShape(Rectangle())
            }
            .shrinkButton() //Not shrinkPress: its raw DragGesture would claim the scroll's pan
            .instantPressDelivery()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var messageSection: some View {
        if let message {
            Text(message)
                .font(.body(14, .italic))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(6)
                .padding(.top, Spacing.sm) //Paragraph separation: its own 6pt leading needs more than a line gap
        }
    }
}
