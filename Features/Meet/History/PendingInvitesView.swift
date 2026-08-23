//
//  PendingInvitesView.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct PendingInvitesView: View {
    
    //Injected
    let inviteDays: [InviteDay]
    let ui: HistoryUIState
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.lg) {
            ForEach(inviteDays) { inviteDay in
                daySection(inviteDay)
            }
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.bottom, Spacing.clearance)
    }
}

extension PendingInvitesView {
    
    private func daySection(_ inviteDay: InviteDay) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(FormatEvent.dayAndTime(inviteDay.day, withHour: false))
                .font(.body(18, .bold))
                .foregroundStyle(Color(white: 0.25))
            VStack(spacing: 0) {
                ForEach(inviteDay.invites) {pending in
                    InvitedCard(pending: pending,
                                showsDivider: pending.id != inviteDay.invites.last?.id,
                                isExpanded: ui.expandedInvite == pending.id,
                                showsChevron: !isShadowed(pending.id),
                                onToggle: {
                                    withAnimation(.expand) {
                                        ui.expandedInvite = ui.expandedInvite == pending.id ? nil : pending.id
                                    }
                                })
                }
            }
            .modifier(InvitedDayBackground())
        }
    }

    private func isShadowed(_ card: InviteCardID) -> Bool {
        guard let open = ui.expandedInvite else { return false }
        return open.inviteID == card.inviteID && open != card
    }
}

private struct InvitedCard: View {
    
    //Injected
    let pending: PendingInvite
    let showsDivider: Bool //False on the last invite of a day — nothing follows it to separate
    let isExpanded: Bool
    let showsChevron: Bool //False while another day's card for this same invite is open
    let onToggle: () -> Void
    
    //Local view state
    @State private var detailHeight: CGFloat = 0
    
    private var invite: EventProfile { pending.invite }
    
    //This card's own day — not proposedTimes.first, which is the invite's earliest day and
    //would label every card of a multi-day invite with the same time.
    private var proposedTime: Date { pending.time.date }
    
    //Same rule as ConfirmMessageSection's checkMessage: whitespace-only counts as no message
    private var message: String? {
        guard let text = invite.event.message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }
    
    
    var body: some View {
        
        HStack(alignment: .top, spacing: Spacing.md) {
            circlePhoto
            
            textRows
        }
        .padding(.vertical, Spacing.xs)
    }
    
    
    @ViewBuilder
    private var circlePhoto: some View {
        if let image = invite.image {
            SmallImage(image: image, size: 42, isCircle: true)
        }
    }
    
    private var timeAndWhat: String {
        "\(invite.event.type.longTitle) · \(FormatEvent.hourTime(proposedTime))"
    }
    
    private var textRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                nameRow
                
                timeRow
            }
            
            expandedDetail
            
            if showsDivider {
                LightDivider()
                    .padding(.top, Spacing.md)
            }
        }
    }
    
    //firstTextBaseline, not centres: differently-sized type reads as misaligned when its
    private var nameRow: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(invite.profile.name)
                .font(.title(18, .semibold))
                .foregroundStyle(Color.textPrimary)
            
            Spacer(minLength: 16)
            
            Text("Option \(pending.time.optionNumber)")
                .font(.body(12, .regular))
                .foregroundStyle(Color(white: 0.75))
        }
    }
    
    //Centred rather than baselined — the chevron is a glyph, and a baseline puts it too low
    private var timeRow: some View {
        HStack(spacing: 16) {
            Text(timeAndWhat)
                .font(.body(15, .medium))
                .foregroundStyle(Color(white: 0.7))
            
            Spacer(minLength: 16)
            
            chevronSlot
        }
    }

    //Hidden by effects, never removed: a view in a removal transition drops out of layout and
    //keeps its last frame, so it hung in place while the reveal pushed its row down. The
    //.animation sits INSIDE the placement — the fade runs on .transition while the row's slide
    //stays with the ambient .expand.
    private var chevronSlot: some View {
        cardChevron
            .opacity(showsChevron ? 0.7 : 0)//Tad Lighter -> looks better
            .blur(radius: showsChevron ? 0 : 6) //the .blurReplace look, without leaving layout
            .animation(.transition, value: showsChevron)
            .allowsHitTesting(showsChevron) //Its expanded hit area must not outlive the glyph
    }
    
    //The invite's message wears the same treatment as on the confirm-invite screen
    //(ConfirmMessageSection.messageText) — 14pt italic, textSecondary, 6pt line spacing —
    //so one message reads identically wherever it's shown.
    private var expandedDetail: some View {
        Group {
            if let message {
                Text(message)
                    .font(.body(14, .italic))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(6)
                    .padding(.top, Spacing.xxs) //The gap above the detail, revealed together with it
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true) //Keep every line — the clamp must not compress it
        .getHeight($detailHeight) //ABOVE the clamp, so it measures the natural height, not 0
        .frame(height: isExpanded ? detailHeight : 0, alignment: .top)
        .clipped()
    }
    
    
    
    private var cardChevron: some View {
        Button {
            onToggle()
        } label: {
            Image(.dropdownHistory)
                .foregroundStyle(Color(red: 0.45, green: 0.43, blue: 0.44))
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .expandHitArea()
        }
        .growButton(shadow: nil)
    }
}

//DropdownHistory

private struct InvitedDayBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md) //Same token as the row's avatar ↔ text gap, so the avatar sits equidistant from the card edge and from the name
            .padding(.vertical, -Spacing.xs) //Cancels out the vertical padding each card has, at the top and the bottom of the card
            .frame(maxWidth: .infinity)
            .background(Color.white, in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.01), radius: 5, x: 0, y: 0)
            .shadow(color: .black.opacity(0.02), radius: 3.5, x: 0, y: 1)
    }
}

