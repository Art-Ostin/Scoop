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
    
    private let user: UserProfile
    
    @ObservationIgnored private let eventManager: EventManager
    @ObservationIgnored private let cacheManager: CacheManaging
    @ObservationIgnored private let userManager: UserManager
    @ObservationIgnored private let cycleManager: CycleManager
    
    
    init(user: UserProfile, eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.user = user
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
        
        do {
            showRespondToProfilesToRefresh = try await cycleManager.showRespondToProfilesToRefresh()
        } catch {
            print("Could not save issue")
        }
        
        profileRecs = try await cycleManager.fetchPendingCycleRecommendations()
        Task { await cacheManager.loadProfileImages(profileRecs.map{$0.profile})}
    }
    
}
