//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

enum ResponseType: Codable {
    case original, modified
}

struct RespondDraft: Codable  {
    
    var originalInvite: OriginalInvite
    var newTime: NewTimeDraft { didSet { respondType = .modified}}
    var newEvent: EventDraft 
    var respondMessage: String?
    var respondType: ResponseType
    
    init(event: UserEvent, userId: String) {
        let selectedDay = event.proposedTimes.firstAvailableDate
        self.originalInvite = OriginalInvite(event: event, selectedDay: selectedDay)
        self.newTime = NewTimeDraft(event: event, proposedTimes: .init())
        self.newEvent = EventDraft(initiatorId: event.otherUserId, recipientId: userId, location: event.location)
        self.respondType = .original
    }
}

struct OriginalInvite: Codable {
    let event: UserEvent
    var selectedDay: Date?
}

struct NewTimeDraft: Codable {
    let event: UserEvent
    var proposedTimes: ProposedTimes
}
