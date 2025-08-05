//
//  DailyProfilesTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation

@Observable class MeetUpViewModel {

    @ObservationIgnored var selection: Int = 0
    
    
    let userStore: CurrentUserStore
    let profileManager: ProfileManaging
    let defaults: UserDefaults
    
    
    let profiles: [UserProfile] = []
    
    
    let dateKey = "dailyProfilesDate"
    let profileKey = "dailyProfiles"
    let showProfilesKey = "showDailyProfiles"
    
    
    init(userStore: CurrentUserStore, profileManager: ProfileManaging, defaults: UserDefaults = .standard) {
        self.userStore = userStore
        self.profileManager = profileManager
        self.defaults = defaults
        self.state = defaults.bool(forKey: showProfilesKey) ? .twoDailyProfiles : .intro
    }
    
    var state: MeetSections?
    
    
    //Functionality to load the TwoDailyProfiles
    
    
    
    func load () async {
        if defaults.bool(forKey: showProfilesKey) {
            if let data = defaults.data(forKey: profileKey),
               let lastDate = defaults.object(forKey: dateKey) as? Date,
               Date().timeIntervalSince(lastDate) < 300,
               let stored = try? JSONDecoder().decode([UserProfile].self, from: data) {
                await assignProfiles(stored)
                await MainActor.run {
                    self.selection = 0
                    self.state = .twoDailyProfiles
                }
            } else {
                await MainActor.run { self.state = .intro }
            }
        }
    }
    
    
    func refresh() async {
        do {
            let fetched = try await profileManager.getRandomProfile()
            await assignProfiles(fetched)
            if let data = try? JSONEncoder().encode(fetched) {
                defaults.set(data, forKey: profileKey)
            }
            defaults.set(Date(), forKey: dateKey)
            defaults.set(true, forKey: showProfilesKey)
            await MainActor.run {
                self.state = .twoDailyProfiles
                self.selection = 0
            }
        } catch {
            print("Error")
        }
    }
    
    private func assignProfiles(_ profiles: [UserProfile]) async {
        for profile in profiles {
            try? await userStore.loadProfile(profile)
        }
    }
}
