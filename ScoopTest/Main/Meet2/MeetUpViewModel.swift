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
        Task { await loadTwoDailyProfiles()}
    }    

    func updateTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        let profiles = try? await dep.profileManager.getRandomProfile()
        guard let newProfiles = profiles else { return }
        shownDailyProfiles = newProfiles
        manager.setTwoDailyProfiles(newProfiles)
    }
    
    //Gets two Daily Profiles from UserDefaults and saves them to cache upon Launch
    func loadTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        if manager.getDailyProfileTimerEnd() != nil {
            let ids = manager.getTwoDailyProfiles()
            var results: [UserProfile] = []
            await withTaskGroup(of: UserProfile?.self) { group in
                for id in ids {
                    group.addTask { try? await self.dep.profileManager.getProfile(userId: id) }
                }
                Task { await dep.cacheManager.loadProfileImages(results)}
                for await p in group { if let p { results.append(p) } }
            }
            shownDailyProfiles = results
            print("populated two daily profiles into the Meet Up view ")
        } else {
            print("No daily profiles, so none added")
        }
    }
}
