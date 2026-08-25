//
//  PendingContainer.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct PendingInvitesView: View {
    
    //Injected
    let invites: [EventProfile]
    let expiredInvites: [EventProfile]
    let ui: HistoryUIState

    var body: some View {
        VStack(spacing: 0) {
            if !invites.isEmpty {
                pendingSection
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl) //The card → the count that closes it
            }
            expiredSection
                .padding(.bottom, Spacing.clearance * 2)
                .padding(.horizontal, Spacing.gutter)
                .padding(.top, 12)
        }
    }
}

//The unanswered invites, behind a heading that reveals them
extension PendingInvitesView {
    
    private var expiredSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            expiredHeader
            
            expiredDetail
                .drawer(isOpen: ui.showsExpired)
        }
    }
    
    //The whole heading is the control, its chevron turning down as the section opens
    private var expiredHeader: some View {
        Button {
            withAnimation(.unfold) { ui.showsExpired.toggle() } //Not .expand: six invites is a tall reveal
        } label: {
            HStack {
                Text("Unanswered Invites")
                    .font(.body(18, .bold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body(15, .bold))
                    .foregroundStyle(Color.textSecondary)
                    .rotationEffect(.degrees(ui.showsExpired ? 90 : 0)) //Right → down, as the rows' own chevrons
                    .animation(.toggle, value: ui.showsExpired)
                    .padding(.trailing, 6) //Geometry: optical inset — the glyph's box is wider than its stroke
            }
            .expandHitArea(Spacing.sm) //One text line is a thin target, and the Spacer's gap carries no shape of its own
        }
        .subtleShrinkButton() //Not shrinkPress, whose raw DragGesture would claim the pager's pan
        .instantPressDelivery()
    }
    
    //What the heading reveals: the note the section needs, then the card of unanswered invites
    private var expiredDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Invites where all your invited times have expired. They can still respond by proposing a new time.")
                .infoText()
                .padding(.top, Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !expiredInvites.isEmpty {
                expiredCard
                    .padding(.top, Spacing.sm) //Note → its card
            }
        }
        .padding(.top, Spacing.hairline) //The nudge the heading kept above its note
    }
    
    private var expiredCard: some View {
        InviteListCard(rowCount: expiredInvites.count) {
            ForEach(expiredInvites) { event in
                ExpiredEventCard(event: event,
                                 showsDivider: event.id != expiredInvites.last?.id,
                                 isExpanded: ui.expandedInvite == event.id,
                                 onToggle: { toggle(event.id) })
            }
        }
    }
}




extension PendingInvitesView {
    
    private func toggle(_ inviteID: String) {
        withAnimation(.expand) {
            ui.expandedInvite = ui.expandedInvite == inviteID ? nil : inviteID
        }
    }
}
