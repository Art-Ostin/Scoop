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
    
    let dateKey = "dailyProfilesDate"
    let profileKey = "dailyProfiles"
    let showProfilesKey = "showDailyProfiles"
    
    
    init(userStore: CurrentUserStore, profileManager: ProfileManaging, defaults: UserDefaults = .standard) {
        self.userStore = userStore
        self.profileManager = profileManager
        self.defaults = defaults
        if defaults.bool(forKey: "showDailyProfiles") {
            self.state = .twoDailyProfiles
        } else {
            self.state = .intro
        }
    }
    
    var state: MeetSections?
    
    
    func updateState(_ state:MeetSections) {
        switch state {
        case .twoDailyProfiles:
            defaults.set(true, forKey: showProfilesKey)
            self.state = .twoDailyProfiles
        case .intro:
            defaults.set(false, forKey: showProfilesKey)
            self.state = .intro
        default: break
        }
    }
    
    //Functionality to load the TwoDailyProfiles
    func load () async {
        if let data = defaults.data(forKey: profileKey),
           let lastDate = defaults.object(forKey: dateKey) as? Date,
           Date().timeIntervalSince(lastDate) < 60,
           let stored = try? JSONDecoder().decode([UserProfile].self, from: data) {
            await assignProfiles(stored)
        } else {
            self.state = .twoDailyProfiles
            await refresh()
        }
    }
    
    func refresh() async {
        do {
            let fetched = try await profileManager.getRandomProfile()
            await assignProfiles(fetched)
            if let data = try? JSONEncoder().encode(fetched) {
                defaults.set(data, forKey: profileKey)
            }
            defaults.set(false, forKey: showProfilesKey)
            await MainActor.run { self.state = .intro }
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
