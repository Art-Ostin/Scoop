//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation


@Observable final class DefaultsManager {
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case draftProfile
        case onboardingStep
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    func setDraftProfile(profile: DraftProfile) {
        guard let data = try? JSONEncoder().encode(profile) else {return}
        defaults.set(data, forKey: Keys.draftProfile.rawValue)
    }
    
    func fetchDraftProfile() -> DraftProfile? {
        guard let data = defaults.data(forKey: Keys.draftProfile.rawValue),
            let profile = try? JSONDecoder().decode(DraftProfile.self, from: data)
        else { return nil }
        return profile
    }
    
    var onboardingStep: Int {
        get { defaults.integer(forKey: Keys.onboardingStep.rawValue) }
        set { defaults.set(newValue, forKey: Keys.onboardingStep.rawValue) }
    }
    
    
}
