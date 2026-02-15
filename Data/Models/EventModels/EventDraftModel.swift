//
//  EventDraftModel.swift
//  Scoop
//
//  Created by Art Ostin on 14/02/2026.
//

//As user creates an event, they update this data. When done from this create an event (Codable as saved to defaults)
struct EventDraft: Equatable, Codable {
    var initiatorId: String
    var recipientId: String
    var type: Event.EventType
    var message: String?
    var proposedTimes: ProposedTimes = .init()
    var location: EventLocation?
}
