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


extension InvitesViewModel {
    
    
    //1. Accept the Invite
    func acceptInvite(acceptedInvite: OriginalInvite) async throws {
        print("Invite Accepted")
        
        /*
         var eventProfile = eventProfile
         eventProfile.event.acceptedTime = acceptedTime
         
         try await eventRepo.acceptEvent(eventId: eventProfile.id, acceptedDate: acceptedTime)
         var acceptedEvent = eventProfile.event
         acceptedEvent.acceptedTime = acceptedTime
         
         session.invites.removeAll { $0.id == eventProfile.id }
         session.events.append(eventProfile)
         defaults.deleteRespondDraft(profileId: eventProfile.profile.id)
         */
    }
    
    //2. Respond to Invite with New Time
    func sendNewTime(newTimeEvent: NewTimeDraft) async throws {
        print("New Time Sent")
    }
    
    //3. Send entirely new Invite
    func sendInvite(event: EventDraft) async throws  {
        print("New Invite Sent")
        //Delete the invite from defaults
        defaults.deleteRespondDraft(profileId: event.recipientId)
    }
    
    //4. Decline Invite
    func declineInvite(profile: UserProfile) async throws  {
        print("Invite Declined")
        defaults.deleteRespondDraft(profileId: profile.id)
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




