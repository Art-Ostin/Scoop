//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit

@Observable class MeetViewModel {
        
    let cycleManager: CycleManager
    let cacheManager: CacheManaging
    let sessionManager: SessionManager

    init(cycleManager: CycleManager, sessionManager: SessionManager, cacheManager: CacheManaging) {
        self.cycleManager = cycleManager
        self.sessionManager = sessionManager
        self.cacheManager = cacheManager
    }

    var activeCycle: CycleModel? { sessionManager.activeCycle }

    var invites: [ProfileModel] { sessionManager.invites }

    var profiles: [ProfileModel] { sessionManager.profiles }

    var showProfiles: Bool { sessionManager.showProfiles }

    var showRefresh: Bool { sessionManager.respondToRefresh }
    
    var endTime: Date? { activeCycle?.endsAt.dateValue()}
    
    func reloadWeeklyRecCycle() {
        let count = activeCycle?.cycleStats.pending
        if count == 0 {
            if let cycleId = sessionManager.activeCycle?.id {
                Task { try await cycleManager.deleteCycle(userId: sessionManager.user.userId, cycleId: cycleId) }
            }
            sessionManager.showProfiles = false
        } else {
            sessionManager.respondToRefresh = true
        }
    }

    func createWeeklyCycle() async throws {
        try await cycleManager.createCycle(userId: sessionManager.user.userId)
        await sessionManager.loadProfiles()
        sessionManager.showProfiles = true
    }

    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
}
