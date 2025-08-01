//
//  DailyProfilesTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation

@Observable class MeetUpViewModel {

    
    //Functionality of which Profile to Display
    var selection: Int = 0
    
    
    let userStore: CurrentUserStore
    let profileManager: ProfileManaging
    let defaults: UserDefaults
    
    
    var profile1: UserProfile?
    var profile2: UserProfile?
    var profiles: [UserProfile] { [profile1, profile2].compactMap { $0 } }

    
    let dateKey = "dailyProfilesDate"
    let profileKey = "dailyProfiles"
    let showProfilesKey = "showDailyProfiles"
    
    
    init(userStore: CurrentUserStore, profileManager: ProfileManaging, defaults: UserDefaults = .standard) {
        self.userStore = userStore
        self.profileManager = profileManager
        self.defaults = defaults
    }
    
    func updateState(_ state: MeetSections) {
        
    }
    
    var state: MeetSections? = MeetSections.intro
    
    //Functionality to load the TwoDailyProfiles
    func load () async {
        if let data = defaults.data(forKey: profileKey),
           let lastDate = defaults.object(forKey: dateKey) as? Date,
           Date().timeIntervalSince(lastDate) < 86400,
           let stored = try? JSONDecoder().decode([UserProfile].self, from: data) {
            await assignProfiles(stored)
        } else {
            await refresh()
        }
    }
    
    func refresh() async {
        do {
            let fetched = try await profileManager.getRandomProfile()
            await assignProfiles(fetched)
            if let data = try? JSONEncoder().encode(fetched) {
                defaults.set(data, forKey: profileKey)
                defaults.set(Date(), forKey: dateKey)
            }
        } catch {
            print("Error")
        }
    }
    
    private func assignProfiles(_ profiles: [UserProfile]) async {
        await MainActor.run {
            profile1 = profiles[safe: 0]
            profile2 = profiles[safe: 1]
        }
        for profile in profiles {
            try? await userStore.loadProfile(profile)
        }
    }
}
