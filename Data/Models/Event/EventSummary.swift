//
//  InviteSummary.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/07/2026.
//

import SwiftUI

struct InviteSummary {
    
    let type: Event.EventType
    let time: ProposedTimes
    let place: EventLocation
    let message: String?
    
    
    //When from draft mode
    init?(draft: EventFieldsDraft) {
        guard let place = draft.place else { return nil }
        
        self.type = draft.type
        self.time = draft.time
        self.place = place
        self.message = draft.message
    }
    
    //When From invited event
    init(event: UserEvent) {
        self.type = event.type
        self.time = event.proposedTimes
        self.place = event.location
        self.message = event.message
    }
}
