//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/08/2025.

import Foundation

@Observable class MeetViewModel {
    
    let dep: AppDependencies
    var weeklyRecDoc: WeeklyRecCycle?
    var showWeeklyRecs: Bool
    var showRespondToProfilesToRefresh: Bool
    
    
    init(dep: AppDependencies) {
        self.dep = dep
        self.showWeeklyRecs = dep.sessionManager.showWeeklyRecs ?? false
        self.showRespondToProfilesToRefresh = dep.sessionManager.showRespondToProfilesToRefresh ?? false
    }
    
    func loadWeeklyRecCycle() async {
        do {
            weeklyRecDoc = try await dep.weeklyRecsManager.getWeeklyRecDoc()
        } catch {
            print(error)
        }
    }
    
    func reloadWeeklyRecCycle() {
        let count = weeklyRecDoc?.cycleStats.pending
        if count == 0 {
            Task {
                do {
                    try await dep.weeklyRecsManager.deleteWeeklyRec()
                } catch  {
                    print(error)
                }
            }
            dep.sessionManager.showWeeklyRecs = false
            showWeeklyRecs = false
        } else {
            showRespondToProfilesToRefresh = true
            dep.sessionManager.showRespondToProfilesToRefresh = true
        }
    }
    
    
    
    func createWeeklyCycle() async throws {
        try await dep.weeklyRecsManager.setWeeklyRecs()
        showWeeklyRecs = true
        try await dep.sessionManager.loadprofileRecs()
        
        
    }
    
    
}
