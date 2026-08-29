//
//  AllPendingInvites.swift
//  Scoop
//
//  Created by Art Ostin on 25/08/2026.
//

import SwiftUI



struct PendingInvites: View {
    
    //Injected
    let events: [EventProfile]
    let expandedInvite: String? //Held by the container, so opening a row closes an expired one too
    let onToggle: (String) -> Void
    
    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            HeaderRow(title: "Invites", note: acceptanceNote)
                .padding(.bottom, Spacing.sm)

            InviteListCard(rowCount: events.count) {
                ForEach(events) { event in
                    InvitedCard(event: event,
                                showDivider: event.id != events.last?.id,
                                isExpanded: expandedInvite == event.id,
                                onToggle: { onToggle(event.id) })
                }
            }
        }
    }
    
    private var acceptanceNote: String { // TODO: final copy
        "They have until \(Int(ProposedTimes.acceptanceLead / 3600)) hours before the invite to accept"
    }
}
