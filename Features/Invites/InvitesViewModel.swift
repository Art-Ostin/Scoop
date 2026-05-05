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
    
    func accept(profileId: String) async throws {
        guard let invite = respondVMs[profileId]?.respondDraft.originalInvite, let day = invite.selectedDay else { return }
        try await eventRepo.acceptEvent(eventId: invite.event.id, senderId: invite.event.otherUserId, userId: userId, acceptedTime: day)
        updateInvitesLocally(eventId: invite.event.id, isAccepted: true)
    }
    
    func sendNewTime(profileId: String) async throws {
        guard let newTime = respondVMs[profileId]?.respondDraft.newTime else { return }
        let event = newTime.event
        let rescheduleResponse = RescheduleResponse(eventId: event.id, userId: userId, recipientId: event.otherUserId, oldTimes: event.proposedTimes, newTimes: newTime.proposedTimes)
        try await eventRepo.respondWithNewTime(newTime: rescheduleResponse)
        updateInvitesLocally(eventId: rescheduleResponse.eventId)
    }
    
    func sendNewEvent(profileId: String) async throws {
        guard let draft = respondVMs[profileId]?.respondDraft else { return }
        let eventResponse = EventResponse( oldEvent: draft.originalInvite.event, newEvent: draft.newEvent, userId: userId)
        try await eventRepo.respondWithNewEvent(eventResponse: eventResponse)
        updateInvitesLocally(eventId: eventResponse.eventId)
    }
    
    func decline(profileId: String) async throws {
        guard let event = respondVMs[profileId]?.respondDraft.originalInvite.event else { return }
        try await eventRepo.declineEvent(eventId: event.id, otherUserId: event.otherUserId, userId: userId)
    }
    
    func eventProfile(for profileId: String) -> EventProfile? {
        invites.first { $0.profile.id == profileId}
    }
    
    private func updateInvitesLocally(eventId: String, isAccepted: Bool = false) {
        //1. IF - (a) declined, (b) accepted or (c) new invite sent with (i) new time or (ii) entirely new event - then remove invites in session
        session.removeEvent(id: eventId)
        
        //2. When responded also remove it from defaults, as event responses are stored
        defaults.deleteRespondDraft(eventId: eventId)
        
        //3. if accepted, update session Manager, to remove event from 'invites' and add it to events variable
        if isAccepted {
            session.acceptInvite(eventId: eventId)
        }
    }
}



@Observable final class InvitesUIState {
    //1. To open the profile
    var selectedProfile: UserProfile? = nil

    //2. Confirmation alerts triggered from invite cards (carry otherUserId)
    var showAcceptPopup: String?
    var showNewTimePopup: String?
    var showNewInvitePopup: String?
    var showQuickInvite: String?

    //3. Show the respond Popup Screen
    var respondedToProfile: ProfileResponse?

    //4. Logic with inviting screen
    var showTimePopup: Bool = false
    var hideInviteTitle: Bool = false
    var dismissOffset: CGFloat? = nil

    //5. The details Screen for invites
    var showDetails: Bool = false

    //6. Loaded profile images keyed by profile id
    var profileImages: [String: [UIImage]] = [:]
    
    //7. Determine if a popup is showing and when o h
    var isPopup: Bool { showAcceptPopup != nil || showNewTimePopup != nil || showNewInvitePopup != nil }
    var hideTab: Bool { isPopup || selectedProfile != nil || showQuickInvite != nil || respondedToProfile != nil}
}
