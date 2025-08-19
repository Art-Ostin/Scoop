//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI


final class SessionManager {
    
    private let eventManager: EventManager
    private let cacheManager: CacheManaging
    private let userManager: UserManager
    private let cycleManager: CycleManager
    
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
    }
    

    var profileRecs: [ProfileModel] = []
    var profileInvites: [ProfileModel] = []
    
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
        guard try await cycleManager.checkCycleSatus() else {
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
