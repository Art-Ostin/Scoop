//
//  DefaultsManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 22/08/2025.
//

import Foundation
import FirebaseAuth

//Updates & stores a 'Draft Profile' during onboarding which persists between sessions. Also saves user's onboarding stage
@Observable
final class DefaultsManager: DefaultsManaging {
    
    let defaults: UserDefaults
    private enum Keys: String { case draftProfile, onboardingStep}
    
    //Using the 'didSet' everytime I update the onboardingStep or signUpDraft it saves the change to defaults
    var onboardingStep: Int {
        didSet { defaults.set(onboardingStep, forKey: Keys.onboardingStep.rawValue) }
    }
    
    //A local copy (created on init) stored and referenced in code changes to it triggers changes to defaults
    var signUpDraft: DraftProfile? {
        didSet {
            if let draft = signUpDraft, let data = try? JSONEncoder().encode(draft) {
                defaults.set(data, forKey: Keys.draftProfile.rawValue)
            } else {
                defaults.removeObject(forKey: Keys.draftProfile.rawValue) // clear when nil
            }
        }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.onboardingStep = defaults.object(forKey: Keys.onboardingStep.rawValue) as? Int ?? 0
        if let data = defaults.data(forKey: Keys.draftProfile.rawValue) { signUpDraft = try? JSONDecoder().decode(DraftProfile.self, from: data)}
    }
    
    func createDraftProfile(user: User) {
        signUpDraft = DraftProfile(user: user)
    }
    
    func update<T>(_ keyPath: WritableKeyPath<DraftProfile, T>, to value: T) {
        guard var d = signUpDraft else { return }
        d[keyPath: keyPath] = value
        signUpDraft = d
    }
        
    func deleteDefaults() {
        signUpDraft = nil
        onboardingStep = 0
    }
    
    func advanceOnboarding() { onboardingStep += 1 }
}
