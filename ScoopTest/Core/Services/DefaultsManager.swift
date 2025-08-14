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
        case sentInviteToProfile1
        case sentInviteToProfile2
    }
    
    init(defaults: UserDefaults, firesoreManager: ProfileManaging, cacheManager: CacheManaging) {
        self.defaults = defaults
        self.firestoreManager = firesoreManager
        self.cacheManager = cacheManager
    }
    
    func setDailyProfileTimer(duration: TimeInterval = 40) {
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
    
    func sentInviteToProfile1() {
        defaults.set(true, forKey: Keys.sentInviteToProfile1.rawValue)
    }
    func sentInviteToProfile2() {
        defaults.set(true, forKey: Keys.sentInviteToProfile2.rawValue)
    }
    
    func getInviteToProfile1Status() -> Bool {
        defaults.bool(forKey: Keys.sentInviteToProfile1.rawValue)
    }
    
    func getInviteToProfile2Status() -> Bool {
        defaults.bool(forKey: Keys.sentInviteToProfile1.rawValue)
    }
    
    func refreshInviteStatus() {
        defaults.removeObject(forKey: Keys.sentInviteToProfile1.rawValue)
        defaults.removeObject(forKey: Keys.sentInviteToProfile2.rawValue)
    }
    
}
