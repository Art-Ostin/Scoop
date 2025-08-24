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
    var activeCycle: CycleModel?
}

@MainActor
@Observable class SessionManager {

    private let eventManager: EventManager
    private let cacheManager: CacheManaging
    private let userManager: UserManager
    private let cycleManager: CycleManager
    private let authManager: AuthManaging
    
    private(set) var session: Session?
    
    var showProfiles: Bool = true
    var respondToRefresh: Bool = false

    init(eventManager: EventManager, cacheManager: CacheManaging, userManager: UserManager, cycleManager: CycleManager, authManager: AuthManaging) {
        self.eventManager = eventManager
        self.cacheManager = cacheManager
        self.userManager = userManager
        self.cycleManager = cycleManager
        self.authManager = authManager
    }

    var profiles: [ProfileModel] = []
    var invites: [ProfileModel] = []
    var events: [UserEvent] = []
    
    var user: UserProfile { session!.user }
    var activeCycle: CycleModel? { session?.activeCycle }
    

    func startSession(user: UserProfile) {
        session = Session(user: user)
    }
    
    
    @discardableResult
    func loadUser() async -> AppState {
        guard
            let uid = authManager.fetchAuthUser(),
            let user = try? await userManager.fetchUser(userId: uid)
        else { return .login }
        startSession(user: user)
        guard user.accountComplete else { return .createAccount }

        Task {
            await cacheManager.loadProfileImages([user])
            print("images added to Cache")
        }
        return .app
    }
    
    func loadInvites() async {
        guard let events = try? await eventManager.getUpcomingInvitedEvents(userId: user.userId), !events.isEmpty else { return }
        let input = events.map { (id: $0.otherUserId, event: $0) }
        let invites = await profileLoader(data: input)
        self.invites = invites
        Task { await cacheManager.loadProfileImages(invites.map(\.profile)) }
    }
    
    func loadProfiles() async {
        await loadCycle() // IF not will always return closed
        let status = await cycleManager.checkCycleStatus(userId: user.userId, cycle: activeCycle)
        if status == .closed { showProfiles = false ; return }
        if status == .respond { respondToRefresh = true }
        
        guard let cycleId = session?.activeCycle?.id,
              let ids = try? await cycleManager.fetchCycleProfiles(userId: user.userId, cycleId: cycleId) else { return }
        
        let data = ids.map { (id: $0, event: nil as UserEvent?)}
        profiles = await profileLoader(data: data)
        Task { await cacheManager.loadProfileImages( self.profiles.map{$0.profile})}
    }
    
    func loadEvents() async {
        guard let events = try? await eventManager.getUpcomingAcceptedEvents(userId: user.userId) else {return}
        self.events = events
        Task {
            let input = events.map { (id: $0.otherUserId, event: $0) }
            let profileModels = await profileLoader(data: input)
            await cacheManager.loadProfileImages(profileModels.map(\.profile))
        }
    }
    
    func loadCycle() async {
        guard
            let userId = session?.user.userId,
            let cycleId = session?.user.activeCycleId
        else { return }
        let cycle = try? await cycleManager.fetchCycle(userId: userId, cycleId: cycleId)
        session?.activeCycle = cycle
    }
    
    func profileLoader(data: [(id: String, event: UserEvent?)]) async -> [ProfileModel] {
        return await withTaskGroup(of: ProfileModel?.self, returning: [ProfileModel].self) { group in
            for item in data {
                group.addTask {
                    guard let profile = try? await self.userManager.fetchUser(userId: item.id) else {return nil}
                    let image = try? await self.cacheManager.fetchFirstImage(profile: profile)
                    return ProfileModel(event: item.event, profile: profile, image: image ?? UIImage())
                }
            }
            return await group.reduce(into: []) {result, element  in
                if let element {result.append(element)}
            }
        }
    }
}

