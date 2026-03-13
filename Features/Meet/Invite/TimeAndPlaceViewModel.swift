//
//  TimeAndPlaceViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/02/2026.
//

import SwiftUI

@MainActor
@Observable class TimeAndPlaceViewModel {
    
    let text: String
    let pendingProfile: PendingProfile
    
    
    var event: EventDraft {
        didSet {
            defaults.updateEventDraft(profileId: pendingProfile.profile.id, eventDraft: event)
        }
    }

    let defaults: DefaultsManaging
    let s: SessionManager
    
    //Change this
    var selectedHour: Int = 22
    var selectedMinute: Int = 30

    var showTypePopup: Bool = false
    var showMessageScreen: Bool = false
    var showTimePopup: Bool = false
    var showMapView: Bool = false
    var showAlert: Bool = false
    var isMessageTap: Bool = false
    
    init(defaults: DefaultsManaging, sessionManager: SessionManager, text: String, profile: PendingProfile) {
        self.defaults = defaults
        self.text = text
        self.pendingProfile = profile
        self.s = sessionManager
        let profileId = profile.profile.id
        if let storedEvent = defaults.fetchEventDraft(profileId: profile.profile.id) {
            self.event = storedEvent
        } else {
            event = EventDraft(initiatorId: sessionManager.user.id, recipientId: profileId, type: .drink)
        }
    }
    
    func deleteEventDefault() {
        defaults.deleteEventDraft(profileId: pendingProfile.profile.id)
        event = EventDraft(initiatorId: s.user.id, recipientId: pendingProfile.profile.id, type: .drink)
    }
}
