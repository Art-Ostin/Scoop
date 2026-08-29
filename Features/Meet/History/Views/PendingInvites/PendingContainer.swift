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

    var body: some View {
        VStack(spacing: 0) {

            if !days.isEmpty {
                pendingCalendar
            }
            
    
            
            expiredInvitesView

        }
    }
}

extension PendingInvitesView {
    
    private var pendingCalendar: some View {
        PendingCalendar(inviteDays: days)
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
