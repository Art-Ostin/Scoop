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
    
    
    
    
    func loadWeeklyRecCycle() async {
        do {
            weeklyRecDoc = try await dep.cycleManager.fetchCycle()
        } catch {
            print(error)
        }
    }
    func fetchImage(url: URL) async throws {
        try await cacheManager.fetchImage(for: url)
    }
    
    func reloadWeeklyRecCycle() async {
        
        let count = try await cycleManager.fetchCycle().cycleStats.pending
        
        weeklyRecDoc?.cycleStats.pending
        if count == 0 {
            Task {
                do {
                    try await cycleManager.deleteCycle()
                } catch  {
                    print(error)
                }
            }
            dep.sessionManager.showProfileRecommendations = false
            showWeeklyRecs = false
        } else {
            showRespondToProfilesToRefresh = true
            dep.sessionManager.showRespondToProfilesToRefresh = true
        }
    }
    
    func createWeeklyCycle() async throws {
        try await dep.cycleManager.createCycle()
        showWeeklyRecs = true
        try await dep.sessionManager.loadprofileRecs()
    }
    
}
