//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation

@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownDailyProfiles: [UserProfile] = []
    
    init(dep: AppDependencies) {
        self.dep = dep
        let profiles = loadTwoDailyProfiles()
        shownDailyProfiles = profiles
    }
    
    func createNextTwoDailyProfiles() async {
        let profiles = try? await dep.profileManager.getRandomProfile()
        let ids = profiles?.map({ $0.userId }) ?? []
        dep.defaultsManager.setNextTwoDailyProfiles(ids)
        if let profiles {
            Task { await dep.cacheManager.loadProfileImages(profiles)}
        }
    }
    
    func updateTwoDailyProfiles() async {
        let manager = dep.defaultsManager
        manager.deleteTwoDailyProfiles()
        shownDailyProfiles.removeAll()
        
        let ids = manager.getNextTwoDailyProfiles()
        for id in ids {
            guard let profile = try? await dep.profileManager.getProfile(userId: id) else {return}
            shownDailyProfiles.append(profile)
            manager.setTwoDailyProfiles([profile])
            manager.deleteNextTwoDailyProfiles()
        }
    }
    
    func loadTwoDailyProfiles() -> [UserProfile] {
        let ids = dep.defaultsManager.getTwoDailyProfiles()
        
        var profiles: [UserProfile] = []
        for id in ids {
            Task {
                if let profile = try? await dep.profileManager.getProfile(userId: id) {
                    profiles.append(profile)
                }
            }
        }
        return profiles
    }
}
