//
//  LimitedAccessViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2025.
//

import SwiftUI
import FirebaseAuth

@Observable class OnboardingViewModel {
    
    @ObservationIgnored let authManager: AuthManaging
    @ObservationIgnored let defaultManager: DefaultsManager
    @ObservationIgnored private let sessionManager: SessionManager
    @ObservationIgnored private let userManager: UserManager
    
    
    init(authManager: AuthManaging, defaultManager: DefaultsManager, sessionManager: SessionManager, userManager: UserManager) {
        self.authManager = authManager
        self.defaultManager = defaultManager
        self.sessionManager = sessionManager
        self.userManager = userManager
    }

    func signOut() async throws {
        try await authManager.deleteAuthUser()
        defaultManager.deleteDefaults()
    }
    
    func fetchUser() async throws -> User? {
        await authManager.fetchAuthUser()
    }
        
    func isLoggedIn () async -> Bool {
        guard let user = await authManager.fetchAuthUser() else { return false }
        if defaultManager.signUpDraft == nil {
            defaultManager.deleteDefaults()
            defaultManager.signUpDraft = .init(user: user)
        }
        return true
    }

    func createProfile() async throws {
        guard let signUpDraft = defaultManager.signUpDraft else {
            print("No draft")
            return
        }
        let profile = try userManager.createUser(draft: signUpDraft)
        await sessionManager.startSession(user: profile)
    }
    
    var onboardingStep: Int {
        defaultManager.onboardingStep
    }
    
    //Need to figure out how to make this so when they click "Next Button" this is all that is called
    func saveAndNextStep<T>(kp: WritableKeyPath<DraftProfile, T>, to value: T, updateOnly: Bool = false) {
        if !updateOnly { defaultManager.onboardingStep += 1}
        defaultManager.update(kp, to: value)
    }
}

/*
 func nextStep() {
     defaultManager.onboardingStep += 1
 }
 
 */
