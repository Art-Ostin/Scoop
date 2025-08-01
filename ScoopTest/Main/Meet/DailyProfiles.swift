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
    
    var profiles: [UserProfile] = []
    
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
            await MainActor.run {profiles = stored }
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
            await MainActor.run {profiles = fetched}
            if let data = try? JSONEncoder().encode(profiles) {
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
