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
    var respondType: ResponseType
    var newTime: NewTimeDraft {
        didSet {
            respondType = .modified
        }
    }
    var eventDraft: EventDraft
    
    init(event: UserEvent, userId: String) {
        self.event = event
        self.selectedDate = event.proposedTimes.firstAvailableDate
        self.respondType = .original //Initially
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init(), message: nil)
        self.eventDraft = EventDraft(initiatorId: event.otherUserId, recipientId: userId, type: event.type, message: event.message, proposedTimes: event.proposedTimes, location: event.location)
    }
}

struct NewTimeDraft {
    var event: UserEvent
    var proposedTimes: ProposedTimes
    var message: String?
}
