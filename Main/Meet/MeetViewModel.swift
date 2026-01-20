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
        
    let cycleManager: CycleManager
    let cacheManager: CacheManaging
    let s: SessionManager
    let eventManager: EventManager
    let userManager: UserManager
    
    init(cycleManager: CycleManager, s: SessionManager, cacheManager: CacheManaging, eventManager: EventManager, userManager: UserManager) {
        self.cycleManager = cycleManager
        self.cacheManager = cacheManager
        self.s = s
        self.eventManager = eventManager
        self.userManager = userManager
    }
    
    var activeCycle: CycleModel? { s.activeCycle }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var pendingInvites: [ProfileModel] { s.profiles} // Change later
    
    var user: UserProfile {s.user}
    
    var showProfilesState: showProfilesState? { s.showProfilesState }
    
    var endTime: Date? { activeCycle?.endsAt}
    
    func createWeeklyCycle() async throws {
        let id = try await cycleManager.createCycle(userId: s.user.id)
        try await s.beginCycle(withId: id)
    }
    
    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
    
    func updateEventStatus(eventId: String, status: EventStatus) async throws {
        try await eventManager.updateStatus(eventId: eventId, to: status)
    }
    
    func saveIdealMeetUp(event: EventDraft) async throws {
        guard
            let time = event.time,
            let place = event.location,
            let type = event.type
        else { return }
        let idealMeetUp = IdealMeetUp(time: time, place: place, type: type, message: event.message)
        let encodedMeetUp = try Firestore.Encoder().encode(idealMeetUp)
        try await userManager.updateUser(userId: s.user.id, values: [.idealMeetUp: encodedMeetUp])
    }
    
    func sendInvite(event: EventDraft, profileModel: ProfileModel) async throws {
        let user = s.user
        try await cycleManager.inviteSent(userId: user.id, cycle: s.activeCycle, profileId: profileModel.profile.id)
        Task { try await eventManager.createEvent(draft: event, user: user, profile: profileModel.profile) ; print("Finished task") }
    }
    
    func declineProfile(profileModel: ProfileModel) async throws {
        let user = s.user
        try await cycleManager.declineProfile(userId: user.id, cycle: s.activeCycle, profileId: profileModel.id)
    }
    
    func acceptInvite(profileModel: ProfileModel, userEvent: UserEvent) async throws {
        guard let event = profileModel.event, let id = event.id else { return }
        try await eventManager.updateStatus(eventId: id, to: .accepted)
    }
    
    func loadImages(profileModel: ProfileModel) async -> [UIImage] {
        return await cacheManager.loadProfileImages([profileModel.profile])
    }
    
    var transitionType: DismissTransition = .standard
    
    var dismissTransition: AnyTransition {
        switch transitionType {
        case .standard:
            return  .move(edge: .leading)
        case .actionPerformed:
            return .move(edge: .trailing)
        }
    }
}

enum DismissTransition {
    case standard, actionPerformed
}
