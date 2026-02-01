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
    let eventRepo: EventsRepository
    let userRepo: UserRepository
    
    init(s: SessionManager, imageLoader: ImageLoading, eventRepo: EventsRepository, userRepo: UserRepository) {
        self.imageLoader = imageLoader
        self.s = s
        self.eventRepo = eventRepo
        self.userRepo = userRepo
    }
    
    
    var invites: [ProfileModel] { s.session?.invites }
    
    var profiles: [ProfileModel] { s.session?.profiles }
    
    var pendingInvites: [ProfileModel] { s.profiles} // Change later
    
    var user: UserProfile {s.user}
    
    var showProfilesState: showProfilesState? { s.showProfilesState }
    
    var endTime: Date? { activeCycle?.endsAt}
    
    func createWeeklyCycle() async throws {
        let id = try await cycleManager.createCycle(userId: s.user.id)
        try await s.beginCycle(withId: id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await imageLoader.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventRepo.updateStatus(eventId: eventId, to: status)
    }
        
    func sendInvite(event: EventDraft, profileModel: ProfileModel) async throws {
        let user = s.user
        try await cycleManager.inviteSent(userId: user.id, cycle: s.activeCycle, profileId: profileModel.profile.id)
        Task { try await eventRepo.createEvent(draft: event, user: user, profile: profileModel.profile) ; print("Finished task") }
    }
    
    func declineProfile(profileModel: ProfileModel) async throws {
        let user = s.user
        try await cycleManager.declineProfile(userId: user.id, cycle: s.activeCycle, profileId: profileModel.id)
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
