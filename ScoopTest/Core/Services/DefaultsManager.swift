//
//  UserDefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import Foundation



// Use defaults for (1) Bool -- If they complete onboarding. (2) Date -- Countdown Timer for two Daily profiles (3) Id -- for two dailyProfiles (3) Bool -- If they have sent an invite to either daily profile.


final class DefaultsManager {
    
    @ObservationIgnored private let firestoreManager: ProfileManaging
    @ObservationIgnored private let cacheManager: CacheManaging
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case dailyProfileTimerEnd
        case twoDailyProfiles
    }
    
    init(defaults: UserDefaults, firesoreManager: ProfileManaging, cacheManager: CacheManaging) {
        self.defaults = defaults
        self.firestoreManager = firesoreManager
        self.cacheManager = cacheManager
    }
    
    func startDailyProfileTimer(duration: TimeInterval = 24 * 60 * 60) {
        let endDate = Date().addingTimeInterval(duration)
        defaults.set(endDate, forKey: Keys.dailyProfileTimerEnd.rawValue)
    }
    
    
    func getDailyProfileTimerEnd() -> Date? {
        defaults.object(forKey: Keys.dailyProfileTimerEnd.rawValue) as? Date
    }
    
    func clearDailyProfileTimer() {
        defaults.removeObject(forKey: Keys.dailyProfileTimerEnd.rawValue)
    }
    
    func saveTwoDailyProfiles(_ profiles: [UserProfile]) {
        let ids = profiles.map { $0.userId }
        defaults.set(ids, forKey: Keys.twoDailyProfiles.rawValue)
        print("Saved Profiles")
    }
    
    func deleteTwoDailyProfiles(_ profiles: [UserProfile]) {
        let ids = profiles.map { $0.userId }
        defaults.removeObject(forKey: Keys.twoDailyProfiles.rawValue)
        print("Removed Profiles")
    }
    
    func getTwoDailyProfiles() -> [String] {
        defaults.stringArray(forKey: Keys.twoDailyProfiles.rawValue) ?? []
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
            Task {
                await cacheManager.loadProfile(results)
            }
            return results
        }
    }
}
