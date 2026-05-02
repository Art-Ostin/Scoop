//
//  InvitesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

@MainActor
@Observable class InvitesViewModel {

    let session: SessionManager
    let defaults: DefaultsManaging
    let imageLoader: ImageLoading
    let eventRepo: EventsRepository

    init(session: SessionManager, defaults: DefaultsManaging, imageLoader: ImageLoading, eventRepo: EventsRepository) {
        self.session = session
        self.defaults = defaults
        self.imageLoader = imageLoader
        self.eventRepo = eventRepo
    }
    
    var invites: [EventProfile] {session.invites}
    var userId: String {session.user.id}
    var respondVMs: [String: RespondViewModel] = [:]
    
    
    func respondVM(for invite: EventProfile, image: UIImage) -> RespondViewModel {
        if let existing = respondVMs[invite.profile.id] { return existing }
        let new = RespondViewModel(
            image: image,
            user: invite.profile,
            defaults: defaults,
            sessionManager: session,
            event: invite.event
        )
        respondVMs[invite.profile.id] = new
        return new
    }

    
    //Set up here -> I pass in an eventResponseDraft to the view, not an invite.
    var respondDrafts: [RespondDraft] {
        invites.map { invite in
            RespondDraft(event: invite.event, userId: session.user.id)
        }
    }
            
    func loadImages(profile: UserProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}

//Functions to Respond To Invites
extension InvitesViewModel {
    
    func acceptInvite(eventId: String, senderId: String, acceptedDate: Date) async throws {
        //1. Accept the Event on backend
        try await eventRepo.acceptEvent(eventId: eventId, senderId: senderId, userId: session.user.id, acceptedTime: acceptedDate)
        updateInvitesLocally(eventId: eventId, isAccepted: true)
    }
    
    func sendNewTime(rescheduleResponse: RescheduleResponse) async throws {
        try await eventRepo.respondWithNewTime(newTime: rescheduleResponse)
        updateInvitesLocally(eventId: rescheduleResponse.eventId)
    }
    
    func sendNewEvent(eventResponse: EventResponse) async throws {
        try await eventRepo.respondWithNewEvent(eventResponse: eventResponse)
        updateInvitesLocally(eventId: eventResponse.eventId)
    }
    
    func declineInvite(eventId: String, otherUserId: String) async throws  {
        try await eventRepo.declineEvent(eventId: eventId, otherUserId: otherUserId, userId: userId)
    }
    
    private func updateInvitesLocally(eventId: String, isAccepted: Bool = false) {
        //1. IF - (a) declined, (b) accepted or (c) new invite sent with (i) new time or (ii) entirely new event - then remove invites in session
        session.removeInvitedEventInSession(id: eventId)
        
        //2. When responded also remove it from defaults, as event responses are stored
        defaults.deleteRespondDraft(eventId: eventId)
        
        //3. if accepted, update session Manager, to remove event from 'invites' and add it to events variable
        if isAccepted {
            if let eventProfile = invites.first(where: { $0.id == eventId}) {
                session.updateAcceptedEventInSession(eventProfile: eventProfile)
            }
        }
    }
}





@Observable final class InvitesUIState {
    var selectedProfile: UserProfile? = nil
    var quickInvite: Bool = false
    var declineScreen: Bool? = false
    var acceptScreen: Bool = true
    var showDetails: Bool = false
    var showTimePopup: Bool = false
    var dismissOffset: CGFloat? = nil
    
    var respondedToProfile: ProfileResponse?
    
    
    var profileInvite: UserProfile? {
        didSet {
            quickInvite = true
        }
    }
}




