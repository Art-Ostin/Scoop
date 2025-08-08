//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation
import SwiftUI

@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownDailyProfiles: [UserProfile] = []
    
    
    init(dep: AppDependencies) {
        self.dep = dep
        Task { await loadTwoDailyProfiles()
            print("populated two daily Profiles") }
    }

    func updateTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        let profiles = try? await dep.profileManager.getRandomProfile()
        guard let newProfiles = profiles else { return }
        shownDailyProfiles = newProfiles
        manager.setTwoDailyProfiles(newProfiles)
    }
    
    
    func loadTwoDailyProfiles() async {
        let manager = dep.defaultsManager        
        if manager.getDailyProfileTimerEnd() != nil {
            let ids = manager.getTwoDailyProfiles()
            var results: [UserProfile] = []
            await withTaskGroup(of: UserProfile?.self) { group in
                for id in ids {
                    group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
                }
                for await p in group { if let p { results.append(p) } }
            }
            shownDailyProfiles = results
        } else if !manager.getHasProfileUpdated() {
            await updateTwoDailyProfiles()
            manager.setHasProfileUpdated(true)
            print("Updated status to true")
        }
    }
}



// Issue: will updateTwoDailyProfiles everyTime screen appears (provided I have not clicked on "Two Daily Profiles") I need it to happen only if Two daily profiles has not already been reset.
