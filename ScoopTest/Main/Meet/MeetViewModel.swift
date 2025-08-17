//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation

@Observable class MeetViewModel {
    
    let dep: AppDependencies
    var weeklyRecDoc: RecommendationCycle?
    var showWeeklyRecs: Bool
    var showRespondToProfilesToRefresh: Bool
    
    
    init(dep: AppDependencies) {
        self.dep = dep
        self.showWeeklyRecs = dep.sessionManager.showProfileRecommendations
        self.showRespondToProfilesToRefresh = dep.sessionManager.showRespondToProfilesToRefresh
    }
    
    func loadWeeklyRecCycle() async {
        do {
            weeklyRecDoc = try await dep.cycleManager.fetchCycle()
        } catch {
            print(error)
        }
    }
    
    
    
    func reloadWeeklyRecCycle() {
        let count = weeklyRecDoc?.cycleStats.pending
        if count == 0 {
            Task {
                do {
                    try await dep.cycleManager.deleteCycle()
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
