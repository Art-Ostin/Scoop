//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth


@Observable final class DefaultsManager {
    
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case draftProfile
        case onboardingStep
    }
    
    var onboardingStep: Int {
        didSet { defaults.set(onboardingStep, forKey: Keys.onboardingStep.rawValue) }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.onboardingStep = defaults.object(forKey: Keys.onboardingStep.rawValue) as? Int ?? 0
    }
    
    func setDraftProfile(authUser: AuthDataResult) {
        let profile = DraftProfile(auth: authUser)
        guard let data = try? JSONEncoder().encode(profile) else {return}
        defaults.set(data, forKey: Keys.draftProfile.rawValue)
    }
    
    func fetch() -> DraftProfile? {
        guard let data = defaults.data(forKey: Keys.draftProfile.rawValue),
            let profile = try? JSONDecoder().decode(DraftProfile.self, from: data)
        else { return nil }
        return profile
    }
    
    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T){
        guard var draft = fetch() else { return }
        draft[keyPath: keyPath] = value
        save(draft)
    }
    
    func save(_ draft: DraftProfile) {
        if let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: Keys.draftProfile.rawValue)
        }
        if let draftProfile = fetch() {
            print("Saved draft profile: \(draftProfile)")
        }
    }
    
    func deleteDefaults() {
        defaults.removeObject(forKey: Keys.onboardingStep.rawValue)
        defaults.removeObject(forKey: Keys.draftProfile.rawValue)
        onboardingStep = 0
    }
    
    func advanceOnboarding() { onboardingStep += 1 }

    

    
}
