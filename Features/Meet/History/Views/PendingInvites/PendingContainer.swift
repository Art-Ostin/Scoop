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
    let invites: [EventProfile]
    let expiredInvites: [EventProfile]
    @Bindable var ui: HistoryUIState //Bindable, not let: the expired section drives showsExpired

    var body: some View {
        VStack(spacing: 0) {
            if !invites.isEmpty {
                PendingInvites(events: invites, expandedInvite: ui.expandedInvite, onToggle: { toggle($0) })
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl) //The card → the count that closes it
            }
            
            if !days.isEmpty {
                PendingCalendar(days: days, onTapInvite: { toggle($0) })
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl) //The card → the section that follows it
            }
            
            ExpiredInvites(expiredInvites: expiredInvites,
                           expandedInvite: ui.expandedInvite,
                           showsExpired: $ui.showsExpired,
                           toggle: toggle)
                .padding(.bottom, Spacing.clearance * 2)
                .padding(.horizontal, Spacing.gutter)
                .padding(.top, 12)
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
