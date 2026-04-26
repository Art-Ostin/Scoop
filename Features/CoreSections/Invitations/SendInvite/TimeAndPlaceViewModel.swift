//
//  TimeAndPlaceViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

@MainActor
@Observable class TimeAndPlaceViewModel {
    
    let profile: UserProfile
    let defaults: DefaultsManaging
    let s: SessionManager
    let image: UIImage
    
    var event: EventFieldsDraft {
        didSet {
            defaults.updateEventDraft(profileId: profile.id, eventDraft: event)
        }
    }
        
    init(defaults: DefaultsManaging, sessionManager: SessionManager, profile: UserProfile, image: UIImage) {
        self.defaults = defaults
        self.profile = profile
        self.s = sessionManager
        self.image = image
        self.event = Self.loadEvent(d: defaults, s: sessionManager, p: profile)
    }
    
    private static func loadEvent(d: DefaultsManaging, s: SessionManager, p: UserProfile) -> EventFieldsDraft {
        if let storedEvent = d.fetchEventDraft(profileId: p.id) {
            return storedEvent
        } else {
            return EventFieldsDraft()
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: profile.id)
        event = EventFieldsDraft()
    }
}

