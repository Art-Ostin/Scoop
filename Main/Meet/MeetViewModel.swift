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

    let imageLoader: ImageLoading
    let s: SessionManager
    let userRepo: UserRepository
    let profileRepo: ProfilesRepository
    let eventRepo: EventsRepository

    init(s: SessionManager, imageLoader: ImageLoading, userRepo: UserRepository, profileRepo: ProfilesRepository, eventRepo: EventsRepository) {
        self.imageLoader = imageLoader
        self.s = s
        self.userRepo = userRepo
        self.profileRepo = profileRepo
        self.eventRepo = eventRepo
    }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var pendingInvites: [ProfileModel] { s.profiles} // Change later
    
    var user: UserProfile {s.user}
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await imageLoader.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventRepo.updateStatus(eventId: eventId, to: status)
    }
        
    func updateProfileRec(event: EventDraft, profileModel: ProfileModel, status: ProfileRec.Status) async throws {
        let user = s.user
        try await profileRepo.updateProfileRec(userId: user.id, profileId: profileModel.profile.id, status: status)
        if status == .invited {try await eventRepo.createEvent(draft: event, user: user, profile: profileModel.profile)}
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
