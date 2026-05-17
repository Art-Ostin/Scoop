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
    private(set) var profileImages: [String: [UIImage]] = [:]

    func respondVM(for invite: EventProfile) -> RespondViewModel {
        if let existing = respondVMs[invite.event.id] {
            if let img = invite.image { existing.image = img }
            return existing
        }
        let new = RespondViewModel(
            image: invite.image ?? UIImage(),
            user: invite.profile,
            defaults: defaults,
            sessionManager: session,
            event: invite.event
        )
        respondVMs[invite.event.id] = new
        return new
    }

    func ensureImagesLoaded(for profile: UserProfile) async {
        if profileImages[profile.id] != nil { return }
        profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
    }
}

//Functions to Respond To Invites
extension InvitesViewModel {

    func accept(eventId: String) async throws {
        guard let invite = respondVMs[eventId]?.respondDraft.originalInvite, let day = invite.selectedDay else { return }
        try await eventRepo.acceptEvent(eventId: invite.event.id, senderId: invite.event.otherUserId, userId: userId, acceptedTime: day)
        updateInvitesLocally(eventId: invite.event.id, isAccepted: true)
    }

    func sendNewTime(eventId: String) async throws {
        guard let newTime = respondVMs[eventId]?.respondDraft.newTime else { return }
        let event = newTime.event
        let rescheduleResponse = RescheduleResponse(eventId: event.id, userId: userId, recipientId: event.otherUserId, oldTimes: event.proposedTimes, newTimes: newTime.proposedTimes)
        try await eventRepo.respondWithNewTime(newTime: rescheduleResponse)
        updateInvitesLocally(eventId: rescheduleResponse.eventId)
    }

    func sendNewEvent(eventId: String) async throws {
        guard let draft = respondVMs[eventId]?.respondDraft else { return }
        let eventResponse = EventResponse( oldEvent: draft.originalInvite.event, newEvent: draft.newEvent, userId: userId)
        try await eventRepo.respondWithNewEvent(eventResponse: eventResponse)
        updateInvitesLocally(eventId: eventResponse.eventId)
    }

    func decline(eventId: String) async throws {
        guard let event = respondVMs[eventId]?.respondDraft.originalInvite.event else { return }
        try await eventRepo.declineEvent(eventId: event.id, otherUserId: event.otherUserId, userId: userId)
        updateInvitesLocally(eventId: event.id)
    }

    func eventProfile(for profileId: String) -> EventProfile? {
        invites.first { $0.profile.id == profileId}
    }

    func eventProfile(forEventId eventId: String) -> EventProfile? {
        invites.first { $0.event.id == eventId }
    }

    private func updateInvitesLocally(eventId: String, isAccepted: Bool = false) {
        //1. IF - (a) declined, (b) accepted or (c) new invite sent with (i) new time or (ii) entirely new event - then remove invites in session
        session.removeEvent(id: eventId)

        //2. When responded also remove it from defaults, as event responses are stored
        defaults.deleteRespondDraft(eventId: eventId)

        //3. Drop the cached respond VM so a re-invite from the same person starts fresh
        respondVMs.removeValue(forKey: eventId)

        //4. Drop image cache entries that no longer back any current invite
        let activeProfileIds = Set(invites.map { $0.profile.id })
        profileImages = profileImages.filter { activeProfileIds.contains($0.key) }

        //5. if accepted, update session Manager, to remove event from 'invites' and add it to events variable
        if isAccepted {
            session.acceptInvite(eventId: eventId)
        }
    }
}



@Observable final class InvitesUIState {
    //1. To open the profile
    var selectedProfile: UserProfile? = nil

    //2. Confirmation alerts triggered from invite cards (carry event.id)
    var showAcceptPopup: String?
    var showNewTimePopup: String?
    var showNewInvitePopup: String?
    var showQuickInvite: String?

    //3. Show the respond Popup Screen
    var respondedToProfile: ProfileResponse?

    //4. Logic with inviting screen
    var showTimePopup: Bool = false
    var hideInviteTitle: Bool = false

    //5. The details Screen for invites
    var showDetails: Bool = false

    //6. Determine if a popup is showing and when o h
    var isPopup: Bool { showAcceptPopup != nil || showNewTimePopup != nil || showNewInvitePopup != nil }
    var hideTab: Bool { isPopup || selectedProfile != nil || showQuickInvite != nil || respondedToProfile != nil}
}
