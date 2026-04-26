//
//  RespondEvent.swift
//  Scoop
//
//  Created by Art Ostin on 26/04/2026.
//

import SwiftUI

struct EventResponse {
    let eventId: String
    let otherUserId: String
    let userId: String
    
    let oldTimes: ProposedTimes
    let newTimes: ProposedTimes
    
    let oldType: Event.EventType
    let newType: Event.EventType
    
    let oldPlace: EventLocation
    let newPlace: EventLocation
    
    let newMessage: String?
}

struct EventResponseDraft {
    let type: Event.EventType
    let time: ProposedTime
    let place: EventLocation

    let message: String?
}
