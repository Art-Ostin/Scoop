//
//  InvitesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

@MainActor
@Observable class RespondViewModel {
    
    let s: SessionManager
    let d: DefaultsManaging
    let imageLoader: ImageLoading
    let eventRepo: EventsRepository

    init(s: SessionManager, d: DefaultsManaging, imageLoader: ImageLoading, eventRepo: EventsRepository) {
        self.s = s
        self.d = d
        self.imageLoader = imageLoader
        self.eventRepo = eventRepo
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
    
    //For Defaults to update it
    func updateEventAcceptedTime(eventId: String, acceptedTime: Date) {
        
        
    }
    
    func loadImages(profile: UserProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}


@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var declineScreen: Bool? = false
    var acceptScreen: Bool = true
    var showDetails: Bool = false
    var showTimePopup: Bool = false
    var dismissOffset: CGFloat? = nil
}
