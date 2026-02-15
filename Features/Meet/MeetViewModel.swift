//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit
import FirebaseFirestore
import SwiftUI

@MainActor
@Observable final class MeetViewModel {

    let s: SessionManager
    let defaults: DefaultsManaging
    let userRepo: UserRepository
    let profileRepo: ProfilesRepository
    let eventRepo: EventsRepository
    let imageLoader: ImageLoading
    

    init(s: SessionManager, defaults: DefaultsManaging, userRepo: UserRepository, profileRepo: ProfilesRepository, eventRepo: EventsRepository, imageLoader: ImageLoading) {
        self.imageLoader = imageLoader
        self.s = s
        self.userRepo = userRepo
        self.profileRepo = profileRepo
        self.eventRepo = eventRepo
        self.defaults = defaults
    }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var pendingInvites: [ProfileModel] { s.profiles} // Change later
    
    var user: UserProfile {s.user}
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await imageLoader.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: Event.EventStatus) async throws {
        try await eventRepo.updateStatus(eventId: eventId, to: status)
    }
        
    func updateProfileRec(event: EventDraft? = nil, profileModel: ProfileModel, status: ProfileRec.Status) async throws {
        let user = s.user
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profileModel.profile.id, status: status)
        if status == .invited {
            guard let event else {return}
            try await eventRepo.createEvent(draft: event, user: user, profile: profileModel.profile)
        }
        defaults.deleteEventDraft(profileId: profileModel.profile.id)
    }
    
    func acceptInvite(profileModel: ProfileModel, userEvent: UserEvent) async throws {
        guard let event = profileModel.event, let id = event.id else { return }
        try await eventRepo.updateStatus(eventId: id, to: .accepted)
    }
    
    func loadImages(profileModel: ProfileModel) async -> [UIImage] {
        return await imageLoader.loadProfileImages([profileModel.profile])
    }
}

enum DismissTransition {
    case standard, actionPerformed
}

@Observable final class MeetUIState {
    var selectedProfile: ProfileModel? = nil
    var quickInvite: ProfileModel?
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showSentInvite: Bool?
}

