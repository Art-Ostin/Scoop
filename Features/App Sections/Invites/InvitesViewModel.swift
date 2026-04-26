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
    
    func acceptInvite(eventId: String, acceptedDate: ProposedTime) async throws {
        //1. Accept the Event on backend
        try await eventRepo.acceptEvent(eventId: eventId, acceptedDate: acceptedDate.date)
        updateInvitesLocally(eventId: eventId, isAccepted: true)
    }
    
    func sendNewTime(rescheduleResponse: RescheduleResponse) async throws {
        try await eventRepo.respondWithNewTime(rescheduleResponse)
        updateInvitesLocally(eventId: rescheduleResponse.eventId)
    }
    
    private func updateInvitesLocally(eventId: String, isAccepted: Bool = false) {
        
        //1. Add the event to the events section if its accepted
        if isAccepted {
            if let eventProfile = invites.first(where: { $0.id == eventId}) {
                session.events.append(eventProfile)
            }
        }
        
        //2. Remove the event from the 'invites' section and draft
        session.invites.removeAll { $0.id == eventId }
        defaults.deleteRespondDraft(eventId: eventId)
    }
    
    
    
    
    
    
    //3. Send entirely new Invite
    func sendInvite(eventId: String) async throws  {
        print("New Invite Sent")
        //Delete the invite from defaults
        defaults.deleteRespondDraft(eventId: eventId)
    }
    
    //4. Decline Invite
    func declineInvite(eventId: String) async throws  {
        print("Invite Declined")
        defaults.deleteRespondDraft(eventId: eventId)
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




