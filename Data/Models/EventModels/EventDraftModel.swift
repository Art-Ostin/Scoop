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
    var type: Event.EventType = .drink
    var message: String?
    var proposedTimes: ProposedTimes = .init()
    var location: EventLocation?

    private enum CodingKeys: String, CodingKey {
        case initiatorId, recipientId, type, message, proposedTimes, location
    }
}

extension EventDraft {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        initiatorId = try container.decode(String.self, forKey: .initiatorId)
        recipientId = try container.decode(String.self, forKey: .recipientId)
        type = try container.decodeIfPresent(Event.EventType.self, forKey: .type) ?? .drink
        message = try container.decodeIfPresent(String.self, forKey: .message)
        proposedTimes = try container.decodeIfPresent(ProposedTimes.self, forKey: .proposedTimes) ?? .init()
        location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
    }
}
