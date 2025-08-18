//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI



struct EventInvite {
    var event: UserEvent?
    var profile: UserProfile
    var image: UIImage?
    var id: String { profile.userId}
}


@Observable final class SessionManager {
    
    @ObservationIgnored private let eventManager: EventManager
    @ObservationIgnored private let cacheManager: CacheManaging
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private let userManager: UserManager
    @ObservationIgnored private let cycleManager: CycleManager
    
    
    init(eventManager: EventManager, cacheManager: CacheManaging, profileManager: ProfileManaging, userManager: UserManager, cycleManager: CycleManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.profileManager = profileManager
        self.userManager = userManager
        self.cycleManager = cycleManager
    }
    
    var currentUser: UserProfile? {
        userManager.user
    }

    var profileRecs: [EventInvite] = []
    var profileInvites: [EventInvite] = []

    
    var showProfileRecommendations: Bool = true
    var showRespondToProfilesToRefresh: Bool = false

    
    func loadProfileInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        let data = events.map { (id: $0.otherUserId, event: $0) }
        let invites = await cycleManager.inviteLoader(data: data)
        profileInvites = invites
        await cacheManager.loadProfileImages(profileInvites.map(\.profile))
    }

    func loadprofileRecs () async throws {
        guard try await cycleManager.loadProfileRecsChecker() else {
            showProfileRecommendations = false
            print("no profiles to load")
            return
        }
        showRespondToProfilesToRefresh = try await cycleManager.showRespondToProfilesToRefresh()
        profileRecs = try await cycleManager.fetchPendingCycleRecommendations()
        Task { await cacheManager.loadProfileImages(profileRecs.map{$0.profile})}
    }
    
}
