//
//  UserDefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import Foundation



// Use defaults for (1) Bool -- If they complete onboarding. (2) Date -- Countdown Timer for two Daily profiles (3) Id -- for two dailyProfiles (3) Bool -- If they have sent an invite to either daily profile.


final class UserDefaultsManager {
    
    @ObservationIgnored private let firestoreManager: ProfileManaging
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case refreshDailyProfileTimer
        case twoDailyProfiles
    }
    
    init(defaults: UserDefaults, firesoreManager: ProfileManaging) {
        self.defaults = defaults
        self.firestoreManager = firesoreManager
    }
    
    
    func startDailyProfileTimer() {
        defaults.set(Date(), forKey: Keys.refreshDailyProfileTimer.rawValue)
    }
    
    func getDailyProfileTimer() -> Date {
        guard let date = defaults.object(forKey: Keys.refreshDailyProfileTimer.rawValue) as? Date else {return Date()}
        return date
    }
    
    func saveTwoDailyProfiles(_ profiles: [UserProfile]) {
        let ids = profiles.map { $0.userId }
        defaults.set(ids, forKey: Keys.twoDailyProfiles.rawValue)
    }
    
    
    func retrieveTwoDailyProfiles() async throws -> [UserProfile] {
        let ids = defaults.stringArray(forKey: Keys.twoDailyProfiles.rawValue) ?? []
        return try await withThrowingTaskGroup(of: UserProfile.self, returning: [UserProfile].self) { group in
            for id in ids {
                group.addTask { try await self.firestoreManager.getProfile(userId: id) }
            }
            var results: [UserProfile] = []
            for try await profile in group {
                results.append(profile)
            }
            return results
        }
        
        //I also want to save the images of the TwoDailyProfiles to the Cache. 
    }
}
