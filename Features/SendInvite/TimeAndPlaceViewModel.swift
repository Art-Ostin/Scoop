//
//  TimeAndPlaceViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

@MainActor
@Observable
class TimeAndPlaceViewModel {
    
    let inviteModel: InviteModel
    let defaults: DefaultsManaging
    
    private let session: SessionManager
        
    var event: EventFieldsDraft {
        didSet { updateEventDraft()}
    }
    
    init(inviteModel: InviteModel, defaults: DefaultsManaging, session: SessionManager) {
        self.inviteModel = inviteModel
        self.defaults = defaults
        self.session = session
        self.event = Self.loadEvent(d: defaults, s: session, id: inviteModel.profileId)
    }
    
    private static func loadEvent(d: DefaultsManaging, s: SessionManager, id: String) -> EventFieldsDraft {
        if let storedEvent = d.fetchEventDraft(profileId: id) {
            return storedEvent
        } else {
            return EventFieldsDraft()
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: inviteModel.profileId)
        event = EventFieldsDraft()
    }
    
    func updateEventDraft() {
        defaults.updateEventDraft(profileId: inviteModel.profileId, eventDraft: event)
    }
}


/* Pass in the name, id, Image.
 
 */
