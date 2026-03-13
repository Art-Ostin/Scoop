//
//  InvitesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

@MainActor
@Observable class InvitesViewModel {
    
    let eventProfile: EventProfile
    let s: SessionManager
    let events: EventsRepository
    
    init(eventProfile: EventProfile, s: SessionManager, events: EventsRepository) {
        self.eventProfile = eventProfile
        self.s = s
        self.events = events
    }
    
    var invites: [EventProfile] {s.invites}
    
    
}


@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var quickInvite: EventProfile?
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showSentInvite: RespondToProfileState?
}
