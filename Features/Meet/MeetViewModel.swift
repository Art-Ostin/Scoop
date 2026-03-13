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
        
    var profiles: [PendingProfile] { s.profiles }
    var pendingInvites: [PendingProfile] { s.profiles} // Change later
    
    var user: UserProfile {s.user}
            
    func sendInvite(event: EventDraft, profile: UserProfile) async throws {
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .invited)
        try await eventRepo.createEvent(draft: event, user: user, profile: profile)
        defaults.deleteEventDraft(profileId: profile.id)
    }
    
    func declineProfile(profile: UserProfile) async throws {
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profile.id, status: .declined)
        defaults.deleteEventDraft(profileId: profile.id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await imageLoader.fetchImage(for: url)
    }
    
    func loadImages(profile: UserProfile) async -> [UIImage] {
        return await imageLoader.loadProfileImages(profile)
    }
}

enum DismissTransition {
    case standard, actionPerformed
}

@Observable final class MeetUIState {
    var openProfile: UserProfile? = nil
    var quickInvite: UserProfile?
    var showPendingInvites = false
    var showInfo: Bool = false
    var openPastInvites = false
    var showSentInvite: RespondToProfileState?
}

