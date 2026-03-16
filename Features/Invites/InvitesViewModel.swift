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
    let eventRepo: EventsRepository
    
    init(eventProfile: EventProfile, s: SessionManager, events: EventsRepository) {
        self.eventProfile = eventProfile
        self.s = s
        self.eventRepo = events
    }
    
    var invites: [EventProfile] {s.invites}
    
    func acceptInvite(eventProfile: EventProfile, acceptedTime: Date) async throws {
        var eventProfile = eventProfile
        eventProfile.event.acceptedTime = acceptedTime
        
        try await eventRepo.acceptEvent(eventId: eventProfile.id, acceptedDate: acceptedTime)
        var acceptedEvent = eventProfile.event
        acceptedEvent.acceptedTime = acceptedTime
        
        s.invites.removeAll { $0.id == eventProfile.id }
        s.events.append(eventProfile)
    }
}


@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var quickInvite: EventProfile?
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showSentInvite: RespondedToProfileView?
}
