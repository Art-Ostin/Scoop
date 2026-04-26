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
    
    init(oldEvent: UserEvent, newEvent: EventResponseDraft, userId: String) {
        self.eventId = oldEvent.id
        self.otherUserId = oldEvent.otherUserId
        self.userId = userId
        
        self.oldTimes = oldEvent.proposedTimes
        if let times = newEvent.time {
            self.newTimes = times
        }
        
        self.oldType = oldEvent.type
        self.newType = newEvent.type
        
        self.oldPlace = oldEvent.location
        if let place = newEvent.place {
            self.newPlace = place
        }
        self.newMessage = newEvent.message
    }
}

struct EventResponseDraft: Codable {
    var type: Event.EventType
    var time: ProposedTimes?
    var place: EventLocation?

    var message: String?
}
