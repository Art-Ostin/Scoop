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
    
    //Method to decide which direction to go if forward or back
    var direction: TransitionDirection = .forward
    var transitionStep: AnyTransition {
        switch direction {
        case .forward:
            return  .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .back:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }

    func signOut() async throws {
        try await authManager.deleteAuthUser()
        defaultManager.deleteDefaults()
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
    
    func saveAndNextStep<T>(kp: WritableKeyPath<DraftProfile, T>, to value: T, updateOnly: Bool = false) {
        direction = .forward
        if !updateOnly { withAnimation(.easeInOut) {defaultManager.onboardingStep += 1 }}
        defaultManager.update(kp, to: value)
    }
    
    func goBackStep() {
        guard defaultManager.onboardingStep > 0 else { return }
        direction = .back
        withAnimation(.easeInOut) {
            defaultManager.onboardingStep -= 1
        }
    }
}
enum TransitionDirection { case forward, back }


/*
 func nextStep() {
     defaultManager.onboardingStep += 1
 }
 
 
 func fetchUser() async throws -> User? {
     await authManager.fetchAuthUser()
 }
 */
