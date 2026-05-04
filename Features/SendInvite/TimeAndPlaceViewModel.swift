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
    
    let profileName: String
    let profileId: String
    let profileImage: UIImage
    
    let defaults: DefaultsManaging
    private let session: SessionManager
        
    var event: EventFieldsDraft {
        didSet { updateEventDraft()}
    }
    
    init(
        profileName: String,
        profileId: String,
        profileImage: UIImage,
        defaults: DefaultsManaging,
        session: SessionManager,
    ) {
        self.profileName = profileName
        self.profileId = profileId
        self.profileImage = profileImage
        self.defaults = defaults
        self.session = session
        self.event = Self.loadEvent(d: defaults, s: session, id: profileId)
    }
    
    private static func loadEvent(d: DefaultsManaging, s: SessionManager, id: String) -> EventFieldsDraft {
        if let storedEvent = d.fetchEventDraft(profileId: id) {
            return storedEvent
        } else {
            return EventFieldsDraft()
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: profileId)
        event = EventFieldsDraft()
    }
    
    func updateEventDraft() {
        defaults.updateEventDraft(profileId: profileId, eventDraft: event)
    }
}


/* Pass in the name, id, Image.
 
 */
