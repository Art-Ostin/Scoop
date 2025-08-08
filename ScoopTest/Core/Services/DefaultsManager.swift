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
        case nextTwoDailyProfiles
    }
    
    init(defaults: UserDefaults, firesoreManager: ProfileManaging, cacheManager: CacheManaging) {
        self.defaults = defaults
        self.firestoreManager = firesoreManager
        self.cacheManager = cacheManager
    }
    
    

    func setDailyProfileTimer(duration: TimeInterval = 60) {
        let endDate = Date().addingTimeInterval(duration)
        defaults.set(endDate, forKey: Keys.dailyProfileTimerEnd.rawValue)
    }
    func getDailyProfileTimerEnd() -> Date? {
        guard let end = defaults.object(forKey: Keys.dailyProfileTimerEnd.rawValue) as? Date else { return nil }
        if end <= .now { clearDailyProfileTimer(); return nil }
        return end
    }
    func clearDailyProfileTimer() {
        defaults.removeObject(forKey: Keys.dailyProfileTimerEnd.rawValue)
    }
    
    
    
    func setNextTwoDailyProfiles(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.nextTwoDailyProfiles.rawValue)
    }
    func getNextTwoDailyProfiles() -> [String] {
        defaults.stringArray(forKey: Keys.nextTwoDailyProfiles.rawValue) ?? []
    }
    func deleteNextTwoDailyProfiles() {
        defaults.removeObject(forKey: Keys.nextTwoDailyProfiles.rawValue)
    }
    
    
    func setTwoDailyProfiles(_ profiles: [UserProfile]) {
        let ids = profiles.map { $0.userId }
        defaults.set(ids, forKey: Keys.twoDailyProfiles.rawValue)
    }
    func getTwoDailyProfiles() -> [String] {
        defaults.stringArray(forKey: Keys.twoDailyProfiles.rawValue) ?? []
    }
    func deleteTwoDailyProfiles() {
        defaults.removeObject(forKey: Keys.twoDailyProfiles.rawValue)
    }
    
    func loadTwoDailyProfiles() async throws -> [UserProfile] {
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
                await cacheManager.loadProfileImages(results)
            }
            return results
        }
    }
}
