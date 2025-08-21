//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit

@MainActor
@Observable final class MeetViewModel {
        
    let cycleManager: CycleManager
    let cacheManager: CacheManaging
    let s: SessionManager
    
    init(cycleManager: CycleManager, s: SessionManager, cacheManager: CacheManaging) {
        self.cycleManager = cycleManager
        self.s = s
        self.cacheManager = cacheManager
    }
    
    var activeCycle: CycleModel? { s.activeCycle }
    
    var invites: [ProfileModel] { s.invites }
    
    var profiles: [ProfileModel] { s.profiles }
    
    var showProfiles: Bool { s.showProfiles }
    
    var showRefresh: Bool { s.respondToRefresh }
    
    var endTime: Date? { activeCycle?.endsAt.dateValue()}
    
    func reloadWeeklyCycle() {
        let count = activeCycle?.cycleStats.pending
        if count == 0 {
            if let cycleId = activeCycle?.id {
                Task { try await cycleManager.deleteCycle(userId: s.user.userId, cycleId: cycleId)}
            }
            s.showProfiles = false
        } else {
            s.respondToRefresh = true
        }
    }
    
    func createWeeklyCycle() async throws {
        let _ = try await cycleManager.createCycle(userId: s.user.userId)
        await s.loadUser()
        await s.loadCycle()
        await s.loadProfiles()
        s.showProfiles = true
    }

    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
}
