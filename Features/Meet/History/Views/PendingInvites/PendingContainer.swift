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
    let upcomingEvents: [EventProfile] //Accepted events from today on: each takes its day's row in the calendar
    let expiredInvites: [EventProfile]
    @Bindable var ui: HistoryUIState //Bindable, not let: the expired section drives showsExpired

    let images: (EventProfile) -> [UIImage] //The card's pages for an invite — each lens presents its own card
    let onViewEvent: (EventProfile, EventZoomDeparture, InviteSummary) -> Void //A meeting card's "View Event": the owner leaves History for the event, carrying the card's details

    private var hasCalendar: Bool { !days.isEmpty || !upcomingEvents.isEmpty } //A meeting alone still earns the calendar

    var body: some View {
        VStack(spacing: 0) {
            if hasCalendar {
                pendingCalendar
            } else {
                pendingPlaceholder
            }

            if !expiredInvites.isEmpty {
                expiredSection //No heading or explanation when nothing has expired
            }
        }
        .padding(.bottom, Spacing.clearance + Spacing.xl) //Past the ✕, with room: the Calendar View's bottom
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
    
    //The Calendar View's own rows, so the two calendars can't drift apart — here in a white card: the
    //Calendar View is a screen of its own, but this page is one tab of History's pager.
    //Geometry: inside the card's 16 + 12pt insets, 4 × 54pt faces 8pt apart and a 12pt gap leave the date
    //67pt on a 375pt iPhone — the widest ("Wed 20 May", ~92pt) shrinks to ~73%, above the 0.7 floor
    private var pendingCalendar: some View {
        InviteListCard(insetsContent: false) {
            CalendarPendingEvents(invites: days,
                                  acceptedEvents: upcomingEvents,
                                  onOpen: { _, _ in }, //A sent invite's card has no draft to pose on the tapped day
                                  card: inviteCard,
                                  meetingCard: meetingCard,
                                  facesPerLine: 4,
                                  collapsesOverflow: true, //Five or more faces fold behind a +N chip
                                  faceSpacing: Spacing.xs)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs) //A 72pt row leaves its lens 9pt: this lifts the first and last off the card's edge, level with the sides
        }
        .padding(.horizontal, Spacing.gutter) //The card's edge on the title's
    }

    //Pending lenses and expired avatars open the same sent-invite card
    private func inviteCard(_ invite: EventProfile) -> AnyView {
        AnyView(ViewInvite(inviteSummary: InviteSummary(event: invite.event),
                           images: images(invite), //Read inside the card, so a set that loads while it is up reaches the pager
                           name: invite.profile.name,
                           title: "Invited \(invite.profile.name)"))
    }

    private func meetingCard(_ meeting: EventProfile) -> AnyView {
        guard let time = meeting.event.acceptedTime else { return AnyView(EmptyView()) }
        let summary = InviteSummary(accepted: meeting.event, at: time) //One summary: the card and the flight's copy of it can't drift
        return AnyView(ViewInvite(inviteSummary: summary,
                                  images: images(meeting),
                                  name: meeting.profile.name,
                                  title: "Meeting \(meeting.profile.name)")
            .eventZoomLeadingAction("View Event") { onViewEvent(meeting, $0, summary) })
    }

    //Off the card, on the canvas: live invites sit raised, lapsed ones on the ground. The card's edge
    //ends the calendar, so no rule and no outsized gap
    private var expiredSection: some View {
        VStack(spacing: Spacing.lg) { //Tighter than the gap above: the heading reads with the avatars it explains
            expiredTitle
            expiredEvents
        }
        .padding(.top, Spacing.xl)
    }

    private var expiredTitle: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Expired Invites")
                .font(.body(18, .italic))
                .foregroundStyle(Color.textPrimary)

            Text("Invites where all your invited times have expired. They can still respond by proposing a new time")
                .customSubtitle(lineSpacing: Spacing.xxs, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading) //A wrapped block is only as wide as its longest line: unframed, it centres off the card's edge
        .padding(.horizontal, Spacing.gutter)
    }
    
    private var expiredEvents: some View {
        HistoryExpiredInvites(expiredInvites: expiredInvites, card: inviteCard)
            .padding(.horizontal, Spacing.gutter) //Edge to edge with the card above
    }
}

extension PendingInvitesView {

    private func toggleExpired(_ inviteID: String) {
        withAnimation(.expand) {
            ui.expandedExpired = ui.expandedExpired == inviteID ? nil : inviteID
        }
    }
}
