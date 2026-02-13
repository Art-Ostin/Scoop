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
    var event: EventDraft
    var profile: ProfileModel?

    let defaults: DefaultsManaging
    let s: SessionManager
    
    // Persisted time selection even before any day is picked.
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
        self.event = EventDraft(initiatorId: sessionManager.user.id, recipientId: profile?.profile.id ?? "", type: .drink)
    }
}
