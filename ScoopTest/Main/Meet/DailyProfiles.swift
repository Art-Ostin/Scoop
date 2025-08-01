//
//  DailyProfilesTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation

@Observable class DailyProfilesStore {

    let userStore: CurrentUserStore
    let profileManager: ProfileManaging
    let defaults: UserDefaults
    
    
    var profile1: UserProfile?
    var profile2: UserProfile?    
    
    let dateKey = "dailyProfilesDate"
    let profileKey = "dailyProfiles"
    
    init(userStore: CurrentUserStore, profileManager: ProfileManaging, defaults: UserDefaults = .standard) {
        self.userStore = userStore
        self.profileManager = profileManager
        self.defaults = defaults
    }
    
    func load () async {
        if let data = defaults.data(forKey: profileKey),
           let lastDate = defaults.object(forKey: dateKey) as? Date,
            Date().timeIntervalSince(lastDate) < 86400,
           let stored = try? JSONDecoder().decode([UserProfile].self, from: data) {
            await MainActor.run {
                profile1 = stored[safe: 0]
                profile2 = stored[safe: 1]
            }
            for profile in stored {
                try? await userStore.loadProfile(profile)
            }
        } else {
            await refresh()
        }
    }
    
    func refresh() async {
        do {
            let fetched = try await profileManager.getRandomProfile()
            await MainActor.run {
                profile1 = fetched[safe: 0]
                profile2 = fetched[safe: 1]
            }
            if let data = try? JSONEncoder().encode(fetched) {
                defaults.set(data, forKey: profileKey)
                defaults.set(Date(), forKey: dateKey)
            }
            for profile in fetched {
                try? await userStore.loadProfile(profile)
            }
        } catch {
            print("Error")
        }
    }
}
