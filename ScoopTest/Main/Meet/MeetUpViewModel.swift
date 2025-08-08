//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation



@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownProfiles: [UserProfile] = []
    
    init(dep: AppDependencies) {
        self.dep = dep
    }
    
    func createTwoDailyProfiles() async {
        let profiles = try? await dep.profileManager.getRandomProfile()
        if let profiles {
            for profile in profiles {
                guard !shownProfiles.contains(where: { $0.id == profile.id }) else {
                    return
                }
                shownProfiles.append(profile)
            }
            dep.defaultsManager.saveTwoDailyProfiles(profiles)
        }
    }
    
    func deleteTwoDailyProfiles() async {
        let ids = dep.defaultsManager.getTwoDailyProfiles()
        var profiles: [UserProfile] = []
        for id in ids {
            let profile = try? await dep.profileManager.getProfile(userId: id)
            if let profile {
                profiles.append(profile)
            }
        }
        dep.defaultsManager.deleteTwoDailyProfiles(profiles)
        shownProfiles.removeAll(where: { ids.contains($0.id) })
    }
    
    
    func retrieveTwoDailyProfiles() {
        Task {
            let dailyProfiles  = try? await dep.defaultsManager.retrieveTwoDailyProfiles()
            if let dailyProfiles {
                shownProfiles.append(contentsOf: dailyProfiles)
            }
        }
    }
}
