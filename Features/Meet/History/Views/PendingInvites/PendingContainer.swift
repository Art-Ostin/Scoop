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

            if let selectedEvent {
                HeaderRow(title: "Invites", note: acceptanceNote)
                    .padding(.bottom, Spacing.sm)
                    .padding(.horizontal, Spacing.gutter)

                ZStack(alignment: .top) { //One slot: the leaving and arriving card overlap instead of stacking
                    SelectedDay(event: selectedEvent)
                        .transition(.blurReplace)
                        .id(selectedEvent.id)
                }
                .animation(.transition, value: selectedEvent.id) //Outside the .id, or the swap is instant
                .padding(.horizontal, Spacing.gutter)
                .padding(.bottom, Spacing.lg) //The card → the section that follows it
            }

            if !days.isEmpty {
                PendingCalendar(days: days, expandedInvite: ui.expandedInvite, onTapInvite: { select($0) })
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl) //The card → the section that follows it
            }

            ExpiredInvites(expiredInvites: expiredInvites,
                           expandedInvite: ui.expandedExpired,
                           showsExpired: $ui.showsExpired,
                           toggle: toggleExpired)
                .padding(.bottom, Spacing.clearance * 2)
                .padding(.horizontal, Spacing.gutter)
        }
        .onChange(of: invites.map(\.id), initial: true) { _, _ in reconcileSelection() }
    }
}


extension PendingInvitesView {

    //The invite the tapped face named, resolved against the live list — nil only while the list
    //itself is empty: reconcileSelection re-points a lapsed selection on the render that
    //delivers the lapse. (Pure clock time doesn't re-render; the page recomputes on any
    //session write or pager settle, which is when an expiry lands.)
    private var selectedEvent: EventProfile? {
        guard let id = ui.expandedInvite else { return nil }
        return invites.first { $0.id == id }
    }

    private var acceptanceNote: String {
        "They have until \(Int(ProposedTimes.acceptanceLead / 3600)) hours before the invite to accept"
    }

    //A card is open whenever there is one to show — the section is the point of the screen, and
    //an empty one reads as one that failed to load. The soonest invite opens on arrival — a bare
    //write, so it's there rather than opening itself in front of you. A selection whose invite
    //lapsed mid-session also falls back here, riding whatever update delivered the lapse.
    private func reconcileSelection() {
        guard let soonest = invites.first else { return }
        let resolves = ui.expandedInvite.map { id in invites.contains { $0.id == id } } ?? false
        if !resolves { ui.expandedInvite = soonest.id } //Never clobbers a card already showing
    }

    //A face only ever opens — tapping the one already showing leaves it showing, so the section
    //above can never empty out.
    private func select(_ inviteID: String) {
        guard ui.expandedInvite != inviteID else { return } //The press still bounces; nothing else moves
        withAnimation(.expand) { ui.expandedInvite = inviteID }
    }

    //The expired rows are disclosures on their own id, so opening an archive card can't
    //surrender the selection the card above is showing.
    private func toggleExpired(_ inviteID: String) {
        withAnimation(.expand) {
            ui.expandedExpired = ui.expandedExpired == inviteID ? nil : inviteID
        }
    }
}
