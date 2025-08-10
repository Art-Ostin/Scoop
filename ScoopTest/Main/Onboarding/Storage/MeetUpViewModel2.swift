//
//  DailyProfilesTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation

@Observable class MeetUpViewModel {

    //Functionality of which Profile to Display
    @ObservationIgnored var selection: Int = 0
    
    let dep: AppDependencies
    let defaults: UserDefaults
    
    var profile1: UserProfile?
    var profile2: UserProfile?
    
    let dateKey = "dailyProfilesDate"
    let profileKey = "dailyProfiles"
    let showProfilesKey = "showDailyProfiles"
    
    
    init(dep: AppDependencies, defaults: UserDefaults = .standard) {
        self.dep = dep
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
            let fetched = try await dep.profileManager.getRandomProfile()
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
        await MainActor.run {
            profile1 = profiles[safe: 0]!
            profile2 = profiles[safe: 1]!
        }
        for _ in profiles {
            try? await dep.profileManager.getProfile()
        }
    }
}
