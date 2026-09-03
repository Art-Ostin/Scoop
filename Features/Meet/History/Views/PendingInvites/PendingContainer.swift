//
//  PendingContainer.swift
//  Scoop
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct PendingInvitesView: View {

    //Injected
    let days: [InviteDay]
    let expiredInvites: [EventProfile]
    @Bindable var ui: HistoryUIState //Bindable, not let: the expired section drives showsExpired
    
    let images: (EventProfile) -> [UIImage] //The card's pages for an invite — each lens presents its own card

    var body: some View {
        VStack(spacing: 0) {
            if !days.isEmpty {
                pendingCalendar
            } else {
                pendingPlaceholder
            }

            if !days.isEmpty || !expiredInvites.isEmpty {
                expiredInvitesView
            }
        }
    }
}

extension PendingInvitesView {
    
    private var pendingPlaceholder: some View {
        VStack {
            VStack(spacing: 32) {
                Image("CoolGuys")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(width: 275, height: 275)
                
                
                Text("All the invites you sent and are awaiting a response appear here")
                    .font(.body(18, .medium))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 48)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.bottom, 36)
        }
    }
    
    private var pendingCalendar: some View {
        PendingCalendar(inviteDays: days, ui: ui, images: images)
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.xl) //The card → the section that follows it
    }
    
    private var expiredInvitesView: some View {
        ExpiredInvites(expiredInvites: expiredInvites,
                       expandedInvite: ui.expandedExpired,
                       showsExpired: $ui.showsExpired,
                       toggle: toggleExpired)
            .padding(.bottom, Spacing.clearance * 2)
            .padding(.horizontal, Spacing.gutter)
    }
}





extension PendingInvitesView {

    private func toggleExpired(_ inviteID: String) {
        withAnimation(.expand) {
            ui.expandedExpired = ui.expandedExpired == inviteID ? nil : inviteID
        }
    }
}
