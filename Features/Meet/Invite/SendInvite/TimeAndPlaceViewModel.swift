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
    var event: EventDraft {
        didSet {
            defaults.updateEventDraft(profileId: profile.profile.id, eventDraft: event)
        }
    }
        
    init(defaults: DefaultsManaging, sessionManager: SessionManager, profile: UserProfile) {
        self.defaults = defaults
        self.profile = profile
        self.s = sessionManager
        self.event = Self.loadEvent(d: defaults, s: sessionManager, p: profile)
    }
    
    private static func loadEvent(d: DefaultsManaging, s: SessionManager, p: UserProfile) -> EventDraft {
        if let storedEvent = d.fetchEventDraft(profileId: p.id) {
            return storedEvent
        } else {
            return EventDraft(initiatorId: s.user.id, recipientId: p.id, type: .drink)
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: profile.id)
        event = EventDraft(initiatorId: s.user.id, recipientId: profile.id, type: .drink)
    }
}

@Observable class TimeAndPlaceUIState {
    var showTypePopup: Bool = false
    var showTimePopup: Bool = false
    var showMessageScreen: Bool = false
    var showMapView: Bool = false
    var showAlert: Bool = false
    var isMessageTap: Bool = false
    var showInfoScreen: Bool = false
    let rowHeight: CGFloat = 50
}
