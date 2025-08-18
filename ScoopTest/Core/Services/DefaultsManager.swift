//
//  UserDefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import Foundation



// Use defaults for (1) Bool -- If they complete onboarding. (2) Date -- Countdown Timer for two Daily profiles (3) Id -- for two dailyProfiles (3) Bool -- If they have sent an invite to either daily profile.


final class DefaultsManager {
    
    private let cacheManager: CacheManaging
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case suggestedProfilesTimer
        case suggestedProfiles
    }
    
    init(defaults: UserDefaults, cacheManager: CacheManaging) {
        self.defaults = defaults
        self.cacheManager = cacheManager
    }
    
    func setSuggestedProfilesTimer(duration: TimeInterval = 240) {
        let endDate = Date().addingTimeInterval(duration)
        defaults.set(endDate, forKey: Keys.suggestedProfilesTimer.rawValue)
    }
    
    func getSuggestedProfilesTimer() -> Date? {
        guard let end = defaults.object(forKey: Keys.suggestedProfilesTimer.rawValue) as? Date else { return nil }
        if end <= .now { clearSuggestedProfilesTimer(); return nil }
        return end
    }
    
    func clearSuggestedProfilesTimer() {
        defaults.removeObject(forKey: Keys.suggestedProfilesTimer.rawValue)
    }
    
    func setSuggestedProfiles(_ profiles: [UserProfile]) {
        let ids = profiles.map { $0.userId }
        defaults.set(ids, forKey: Keys.suggestedProfiles.rawValue)
    }
    
    func getSuggestedProfiles() -> [String] {
        defaults.stringArray(forKey: Keys.suggestedProfiles.rawValue) ?? []
    }
    
    func removeSuggestedProfile(_ profile: UserProfile){
        let id = profile.userId
        var ids = defaults.stringArray(forKey: Keys.suggestedProfiles.rawValue)
        ids?.removeAll(where: {$0 == id})
        defaults.set(ids, forKey: Keys.suggestedProfiles.rawValue)
        print("updated suggestedProfiles")
    }
    
    func removeAllSuggestedProfiles() {
        defaults.removeObject(forKey: Keys.suggestedProfiles.rawValue)
    }
}
