//
//  InvitesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

@MainActor
@Observable class InvitesViewModel {

    //Injected
    let session: Session
    let defaults: DefaultsManaging
    let imageLoader: ImageLoading
    let eventRepo: EventsRepository

    //Specific VMs and Images keyed to the user
    var respondVMs: [String: RespondViewModel] = [:]
    var profileVMs: [String: ProfileViewModel] = [:]
    var profileImages: [String: [UIImage]] = [:]
    
    
    init(
        session: Session,
        defaults: DefaultsManaging,
        imageLoader: ImageLoading,
        eventRepo: EventsRepository
    ) {
        self.session = session
        self.defaults = defaults
        self.imageLoader = imageLoader
        self.eventRepo = eventRepo
    }

    var invites: [EventProfile] {session.invites}
}

//Logic to store and pass around respondViewModels
extension InvitesViewModel {
    
    //Key! The RespondVM exists here not in the inviteSlot. 
    func respondVM(for invite: EventProfile) -> RespondViewModel {
        if let existing = respondVMs[invite.event.id] { return existing }
        
        let new = RespondViewModel(
            invite: invite,
            defaults: defaults,
            session: session
        )
        respondVMs[invite.event.id] = new
        return new
    }

    func profileVM(for invite: EventProfile) -> ProfileViewModel {
        if let existing = profileVMs[invite.event.id] { return existing }

        let new = ProfileViewModel(
            profile: invite.profile,
            event: invite.event,
            imageLoader: imageLoader,
            defaults: defaults
        )
        profileVMs[invite.event.id] = new
        return new
    }
    
    func ensureImagesLoaded(for profile: UserProfile) async {
        if profileImages[profile.id] == nil {
            profileImages[profile.id] = await imageLoader.loadProfileImages(profile)
        }
    }
    
        
    

    func draftBinding(for invite: EventProfile) -> Binding<RespondDraft> {
        let vm = respondVM(for: invite)
        return Binding(get: { vm.respondDraft }, set: { vm.respondDraft = $0 })
    }
}



//Functions to Respond To Invites
extension InvitesViewModel {
    
    var userId: String {session.user.id}

    //The only entry point for responding. Every branch calls the appropriate function to respond
    func respond(to type: ProfileResponse, eventId: String) async throws {
        switch type {
        case .accepted:  try await accept(eventId: eventId)
        case .newTime:   try await sendNewTime(eventId: eventId)
        case .newInvite: try await sendNewEvent(eventId: eventId)
        case .decline:   try await decline(eventId: eventId)
        }
    }

    private func accept(eventId: String) async throws {
        guard let invite = respondVMs[eventId]?.respondDraft.originalInvite, let day = invite.selectedDay else { return }
        try await eventRepo.acceptEvent(eventId: invite.event.id, senderId: invite.event.otherUserId, userId: userId, acceptedTime: day)
        updateInvitesLocally(eventId: invite.event.id, isAccepted: true)
    }

    private func sendNewTime(eventId: String) async throws {
        //An empty proposal would overwrite the invite's times with nothing on both edges,
        //leaving the other side an invite with no days to pick. The button gates this too.
        guard let newTime = respondVMs[eventId]?.respondDraft.newTime,
              !newTime.proposedTimes.dates.isEmpty else { return }
        let event = newTime.event
        let rescheduleResponse = RescheduleResponse(eventId: event.id, userId: userId, recipientId: event.otherUserId, oldTimes: event.proposedTimes, newTimes: newTime.proposedTimes)
        try await eventRepo.respondWithNewTime(newTime: rescheduleResponse)
        updateInvitesLocally(eventId: rescheduleResponse.eventId)
    }

    private func sendNewEvent(eventId: String) async throws {
        guard let draft = respondVMs[eventId]?.respondDraft else { return }
        let eventResponse = EventResponse( oldEvent: draft.originalInvite.event, newEvent: draft.newEvent, userId: userId)
        try await eventRepo.respondWithNewEvent(eventResponse: eventResponse)
        updateInvitesLocally(eventId: eventResponse.eventId)
    }

    private func decline(eventId: String) async throws {
        guard let event = respondVMs[eventId]?.respondDraft.originalInvite.event else { return }
        try await eventRepo.declineEvent(eventId: event.id, otherUserId: event.otherUserId, userId: userId)
        updateInvitesLocally(eventId: event.id)
    }

    private func updateInvitesLocally(eventId: String, isAccepted: Bool = false) {
        //1. Update session lists. These two paths are mutually exclusive:
        if isAccepted {
            session.acceptInvite(eventId: eventId)
        } else {
            session.removeEvent(id: eventId)
        }

        //2. When responded also remove it from defaults, as event responses are stored
        defaults.deleteRespondDraft(eventId: eventId)

        //3. Drop the cached VMs so a re-invite from the same person starts fresh
        respondVMs.removeValue(forKey: eventId)
        profileVMs.removeValue(forKey: eventId)

        //4. Drop image cache entries that no longer back any current invite
        let activeProfileIds = Set(invites.map { $0.profile.id })
        profileImages = profileImages.filter { activeProfileIds.contains($0.key) }
    }
}

@Observable final class InvitesUIState {
    var showRespondedCover: ProfileResponse?
    var showQuickResponse: EventProfile?
}
