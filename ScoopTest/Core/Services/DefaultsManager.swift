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
        case onboardingStep
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    func saveUserProfile(profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Keys.draftProfile.rawValue)
        draftUser = profile
    }
    
    @discardableResult
    func loadDraftUser() -> UserProfile? {
        guard
            let data = defaults.data(forKey: Keys.draftProfile.rawValue),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        draftUser = profile
        return profile
    }
    
    var onboardingStep: Int {
        get { defaults.integer(forKey: Keys.onboardingStep.rawValue) }
        set { defaults.set(newValue, forKey: Keys.onboardingStep.rawValue) }
    }
    
    
}
