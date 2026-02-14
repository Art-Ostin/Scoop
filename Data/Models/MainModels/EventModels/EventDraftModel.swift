//
//  EventDraftModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

struct EventDraft: Codable, Equatable {
    var initiatorId: String
    var recipientId: String
    var type: EventType
    var message: String?
    var proposedTimes: ProposedTimes = .init()
    var location: EventLocation?
}
