//
//  SessionManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 16/08/2025.
//

import Foundation
import SwiftUI

struct Session  {
    var user: UserProfile
    var invites: [ProfileModel] = []
    var profiles: [ProfileModel] = []
    var events: [UserEvent] = []
    var activeCycleId: String? { user.activeCycleId }
}


@Observable
final class SessionManager {

    private let eventManager: EventManager
    private let cacheManager: CacheManaging
    private let userManager: UserManager
    private let cycleManager: CycleManager
    private let authManager: AuthManaging
    
    private(set) var session: Session
    
    var showProfileRecommendations: Bool = true
    var showRespondToProfilesToRefresh: Bool = false
    
    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager, authManager: AuthManaging) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.authManager = authManager
    }
    
    var user: UserProfile { session.user }
    var invites: [ProfileModel] { session.invites }
    var profiles: [ProfileModel] { session.profiles }
    var events: [UserEvent] { session.events }
    var activeCycleId: String? { session.activeCycleId }
    
    @discardableResult
    func loadUser() async -> Bool {
        guard
            let uid = authManager.fetchAuthUser(),
            let user = try? await userManager.fetchUser(userId: uid)
        else { return false}
        session.user = user
        return true
        Task { await cacheManager.loadProfileImages([user])}
    }
    
    func loadInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(), !events.isEmpty else { return }
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let invites = await cycleManager.inviteLoader(data: input)
        session.invites = invites
        Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
    }
    
    func loadProfiles() async {
        guard await cycleManager.checkCycleSatus() else {
            showProfileRecommendations = false
            return
        }
        showRespondToProfilesToRefresh = await cycleManager.showRespondToProfilesToRefresh()
        guard let profileRecs = try? await cycleManager.fetchPendingCycleRecommendations() else { return }
        session.profiles = profileRecs
        Task { await cacheManager.loadProfileImages(profileRecs.map{$0.profile})}
    }
    
    func loadEvents() async {
        guard let events = try? await eventManager.getUpcomingAcceptedEvents() else {return}
        session.events = events
        Task {
            let input = events.map { (id: $0.otherUserId, event: $0) }
            let profileModels = await cycleManager.inviteLoader(data: input)
            await cacheManager.loadProfileImages(profileModels.map(\.profile))
        }
    }
}
