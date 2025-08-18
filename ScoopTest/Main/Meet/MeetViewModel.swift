//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation

@Observable class MeetViewModel {
        
    let cycleManager: CycleManager
    let sessionManager: SessionManager
    
    let cacheManager: CacheManaging
    
    
    // Dependencies used: (1) SessionManager (2) CycleManager (3) UserManager
    
    init(dep: AppDependencies) {
        self.cycleManager = dep.cycleManager
        self.sessionManager = dep.sessionManager
        self.cacheManager = dep.cacheManager
    }
    
    func fetchWeeklyRecCycle() async throws -> RecommendationCycle {
        try await cycleManager.fetchCycle()
    }
    
    func fetchWeeklyRecs() -> [EventInvite] {
        sessionManager.profileRecs
    }
    
    func fetchWeeklyInvites() -> [EventInvite] {
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
            Task {
                do {
                    try await cycleManager.deleteCycle()
                } catch  {
                    print(error)
                }
            }
            sessionManager.showProfileRecommendations = false
        } else {
            sessionManager.showRespondToProfilesToRefresh = true
        }
    }
    
    func createWeeklyCycle() async throws {
        try await cycleManager.createCycle()
        try await sessionManager.loadprofileRecs()
    }
    
}
