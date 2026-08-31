//
//  PastEventProposal.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import Foundation

struct PastEventProposal: Codable, Equatable, Identifiable, Hashable {
    //1: Who proposed it, when, and what kind of change it was
    let senderId: String
    let dateSent: Date
    let kind: ProposalKind

    //2: What was proposed
    let type: Event.EventType
    let time: ProposedTimes
    let place: EventLocation
    let message: String?

    var id: Date { dateSent } //Each round carries its own stamp, so nothing stored is needed

    init(retiring oldEvent: UserEvent, now: Date = .now) {
        senderId = oldEvent.otherUserId
        dateSent = oldEvent.createdAt ?? now
        kind = oldEvent.kind
        type = oldEvent.type
        time = oldEvent.proposedTimes
        place = oldEvent.location
        message = oldEvent.message
    }
}
