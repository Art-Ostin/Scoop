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
        print("Load ProfileInvitesCalled")
        guard let events = try? await eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        
        let results = await withTaskGroup(of: EventInvite?.self, returning: [EventInvite].self) {group in
            for e in events {
                group.addTask {
                    guard let p = try? await self.profileManager.getProfile(userId: e.otherUserId) else {return nil}
                    let firstImage = try? await self.cacheManager.fetchFirstImage(profile: p)
                    return EventInvite(event: e, profile: p, image: firstImage ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element in if let element { result.append(element)}}
        }
        profileInvites = results
        await cacheManager.loadProfileImages(results.map(\.profile))
    }
    
    func loadprofileRecs () async throws {
        guard try await cycleManager.loadProfileRecsChecker() else {
            showProfileRecommendations = false
            return
        }
        showRespondToProfilesToRefresh = try await cycleManager.showRespondToProfilesToRefresh()
        profileRecs = try await cycleManager.fetchPendingCycleRecommendations()
        Task { await cacheManager.loadProfileImages(profileRecs.map{$0.profile})}
    }

}
