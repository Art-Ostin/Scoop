//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation
import UIKit

@Observable class MeetViewModel {
        
    let cycleManager: CycleManager
    let sessionManager: SessionManager
    let userManager: UserManager
    let cacheManager: CacheManaging
    
    init(cycleManager: CycleManager, sessionManager: SessionManager, cacheManager: CacheManaging, userManager: UserManager) {
        self.cycleManager = cycleManager
        self.sessionManager = sessionManager
        self.cacheManager = cacheManager
        self.userManager = userManager
    }
    
    func fetchWeeklyRecCycle() async throws -> RecommendationCycle {
        try await cycleManager.fetchCycle()
    }
    
    func fetchWeeklyRecs() -> [ProfileModel] {
        sessionManager.profileRecs
    }
    
    func fetchWeeklyInvites() -> [ProfileModel] {
        sessionManager.profileInvites
    }
    
    func showProfileRecommendations() -> Bool {
        sessionManager.showProfileRecommendations
    }
    
    func showRespondToProfilesToRefresh() -> Bool {
        sessionManager.showRespondToProfilesToRefresh
    }
    
    func fetchTimeUntileEnd() async throws -> Date {
        try await fetchWeeklyRecCycle().endsAt.dateValue()
    }

    func reloadWeeklyRecCycle() async {
        let count = try? await fetchWeeklyRecCycle().cycleStats.pending
        if count == 0 {
            Task { try await cycleManager.deleteCycle() }
            sessionManager.showProfileRecommendations = false
        } else {
            sessionManager.showRespondToProfilesToRefresh = true
        }
    }
    
    func createWeeklyCycle() async throws {
        try await cycleManager.createCycle()
        try await userManager.loadUser()
        try await sessionManager.loadprofileRecs()
        sessionManager.showProfileRecommendations = true
    }

    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
}
