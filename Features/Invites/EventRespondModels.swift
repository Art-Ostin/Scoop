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
    let event: UserEvent
    var selectedDate: Date?
    var draftState: ResponseType
    var newTime: NewTimeDraft
    var eventDraft: EventDraft
    
    init(event: UserEvent, userId: String) {
        self.event = event
        self.selectedDate = event.proposedTimes.firstAvailableDate
        self.draftState = .original //Initially
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init(), message: nil)
        self.eventDraft = EventDraft(initiatorId: event.otherUserId, recipientId: userId, type: event.type, message: event.message, proposedTimes: event.proposedTimes, location: event.location)
    }
}

struct NewTimeDraft {
    var event: UserEvent
    var proposedTimes: ProposedTimes
    var message: String?
}
