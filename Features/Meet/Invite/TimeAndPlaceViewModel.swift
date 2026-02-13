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
    var event: EventDraft {
        didSet { persistDraft() }
    }
    
    var profile: ProfileModel?

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
    
    init(defaults: DefaultsManaging, sessionManager: SessionManager, text: String, profile: ProfileModel? = nil) {
        self.defaults = defaults
        self.text = text
        self.profile = profile
        self.s = sessionManager
        
        //Fetch event Draft if one has been created, or create one if not
        let profileId = profile?.profile.id
        if let profileId, let storedEvent = defaults.fetchEventDraft(profileId: profileId) {
            self.event = storedEvent
        } else {
            event = EventDraft(initiatorId: sessionManager.user.id, recipientId: profileId ?? "", type: .drink)
        }
    }
    
    func persistDraft() {
        guard let profileId = profile?.profile.id else { return }
        defaults.updateEventDraft(profileId: profileId, eventDraft: event)
    }
    
    func deleteEventDefault() {
        guard let profileId = profile?.profile.id else { return }
        defaults.deleteEventDraft(profileId: profileId)
        event = EventDraft(initiatorId: s.user.id, recipientId: profileId, type: .drink)
    }
}


//Delete Event Draft on decline, or accepted from defaults
