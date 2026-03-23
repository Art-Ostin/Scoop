//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

enum EventState {
    case original, modified, new
}

struct EventResponseDraft {
    let event: UserEvent
    var selectedDay: Date?
    var draftState: EventState
    var newTime: NewTimeDraft?
    var eventDraft: EventDraft?
    
    init(event: UserEvent, userId: String) {
        self.event = event
        self.selectedDay = event.proposedTimes.firstAvailableDate
        self.draftState = .original //Initially
        self.newTime = NewTimeDraft(event: event, proposedTimes: [], message: nil)
        self.eventDraft = EventDraft(initiatorId: event.otherUserId, recipientId: userId, type: event.type, message: event.message, proposedTimes: event.proposedTimes, location: event.location)
    }
}

struct NewTimeDraft {
    let event: UserEvent
    let proposedTimes: [ProposedTimes]
    let message: String?
}
