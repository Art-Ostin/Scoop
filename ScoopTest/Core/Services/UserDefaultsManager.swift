//
//  UserDefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import Foundation



// Use defaults for (1) Bool -- If they complete onboarding. (2) Date -- Countdown Timer for two Daily profiles (3) Bool -- If they have sent an invite to either daily profile.


final class UserDefaultsManager {
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case refreshDailyProfileTimer
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    func startDailyProfileTimer() {
        defaults.set(Date(), forKey: Keys.refreshDailyProfileTimer.rawValue)
    }
    
    func getDailyProfileTimer() -> Date {
        guard let date = defaults.object(forKey: Keys.refreshDailyProfileTimer.rawValue) as? Date else {return Date()}
        return date
    }
    
     
    
}
