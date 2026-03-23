//
//  EventRespondModels.swift
//  Scoop
//
//  Created by Art Ostin on 23/03/2026.
//

import SwiftUI

struct EventResponseDraft {
    let event: UserEvent
    let newTime: NewTimeDraft?
    let eventDraft: EventDraft?
}

struct NewTimeDraft {
    let event: UserEvent
    let proposedTimes: [ProposedTimes]
    let message: String?
}
