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
        acceptedEvent.acceptedTime = acceptedDate
        
        s.invites.removeAll { $0.id == eventProfile.id }
        s.events.append(eventProfile)
    }
        
        
        
        guard let eventId = userEvent.id else { return }
        guard let acceptedDate = userEvent.proposedTimes.dates.first?.date else { return }
        try await eventRepo.acceptEvent(eventId: eventId, acceptedDate: acceptedDate)
        var acceptedEvent = userEvent
        acceptedEvent.status = .accepted
        acceptedEvent.acceptedTime = acceptedDate
        let acceptedModel = ProfileModel(event: acceptedEvent, profile: profileModel.profile, image: profileModel.image)

        s.invites.removeAll { $0.id == acceptedModel.id }
        s.pastEvents.removeAll { $0.id == acceptedModel.id }
        if let index = s.events.firstIndex(where: { $0.id == acceptedModel.id }) {
            s.events[index] = acceptedModel
        } else {
            s.events.append(acceptedModel)
        }
        print("Accepted")
    }
    
}


@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var quickInvite: EventProfile?
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showSentInvite: RespondToProfileState?
}
