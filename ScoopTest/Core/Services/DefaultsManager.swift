//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation


@Observable final class DefaultsManager {
    
    private let defaults: UserDefaults
    
    var draftUser: UserProfile?
    
    private enum Keys: String {
        case draftProfile
        case suggestedProfiles
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    func saveUserProfile(profile: UserProfile) {
        defaults.set(profile, forKey: Keys.draftProfile.rawValue)
    }
}
