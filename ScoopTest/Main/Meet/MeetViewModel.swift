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
    let s: SessionManager
    
    init(cycleManager: CycleManager, s: SessionManager, cacheManager: CacheManaging) {
        self.cycleManager = cycleManager
        self.s = s
        self.cacheManager = cacheManager
    }
    

    func fetchWeeklyRecs() -> [ProfileModel] {
        s.profiles
    }
    
    
    
    func fetchWeeklyInvites() -> [ProfileModel] {
        s.profileInvites
    }
    
    func showProfileRecommendations() -> Bool {
        s.showProfileRecommendations
    }
    
    func showRespondToProfilesToRefresh() -> Bool {
        s.showRespondToProfilesToRefresh
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
        try await sessionManager.loadprofileRecs()
        sessionManager.showProfileRecommendations = true
    }

    func fetchImage(url: URL) async throws -> UIImage {
        try await cacheManager.fetchImage(for: url)
    }
}
