//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

enum ResponseType: Encodable {
    case original, modified, new
}

struct RespondDraft: Encodable {
    
    var originalInvite: OriginalInvite
    var newTime: NewTimeDraft { didSet { respondType = .modified}}
    var newEvent: EventDraft { didSet { respondType = .new}}
    var respondMessage: String?
    var respondType: ResponseType
    
    init(event: UserEvent, userId: String) {
        let selectedDay = event.proposedTimes.firstAvailableDate
        self.originalInvite = OriginalInvite(event: event, selectedDay: selectedDay)
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init())
        self.newEvent = EventDraft(initiatorId: event.otherUserId, recipientId: userId, type: event.type, message: event.message, proposedTimes: event.proposedTimes, location: event.location)
        self.respondType = .original
    }
}

struct OriginalInvite: Encodable {
    let event: UserEvent
    var selectedDay: Date?
}

struct NewTimeDraft: Encodable {
    let event: UserEvent
    var proposedTimes: ProposedTimes
}
