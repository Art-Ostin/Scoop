//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

enum ResponseType {
    case original, modified, new
}

struct RespondDraft {
    var originalInvite: OriginalInvite
    var newTime: NewTimeDraft { didSet { respondType = .modified}}
    var newEvent: EventDraft { didSet { respondType = .new}}
    var respondType: ResponseType
    
    init(event: UserEvent, userId: String) {
        let selectedDay = event.proposedTimes.firstAvailableDate
        self.originalInvite = OriginalInvite(event: event, selectedDay: selectedDay, acceptMessage: nil)
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init(), message: nil)
        self.newEvent = EventDraft(initiatorId: event.otherUserId, recipientId: userId, type: event.type, message: event.message, proposedTimes: event.proposedTimes, location: event.location)
        self.respondType = .original
    }
}

struct OriginalInvite {
    let event: UserEvent
    var selectedDay: Date?
    var acceptMessage: String?
}

struct NewTimeDraft {
    let event: UserEvent
    var proposedTimes: ProposedTimes
    var message: String?
}
