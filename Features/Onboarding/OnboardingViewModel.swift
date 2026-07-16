//
//  LimitedAccessViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2025.
//

import SwiftUI
import FirebaseAuth

@Observable class OnboardingViewModel {
    
    //Injected
    @ObservationIgnored let authService: AuthServicing
    @ObservationIgnored var defaultManager: DefaultsManaging
    @ObservationIgnored private let session: Session
    @ObservationIgnored private let userRepo: UserRepository

    //Local state
    @ObservationIgnored private var canAdvance = true //Prevents quick double-tap advances
    var direction: TransitionDirection = .forward

    init(authService: AuthServicing, defaultManager: DefaultsManaging, session: Session, userRepo: UserRepository) {
        self.authService = authService
        self.defaultManager = defaultManager
        self.session = session
        self.userRepo = userRepo
    }

    var transitionStep: AnyTransition {
        switch direction {
        case .forward: .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .back: .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }

    var onboardingStep: Int {
        defaultManager.onboardingStep
    }

    var draftProfile: DraftProfile? {
        defaultManager.signUpDraft
    }

    func signOut() async throws {
        try await authService.deleteAuthUser()
        defaultManager.deleteDefaults()
    }

    func isLoggedIn () async -> Bool {
        guard let user = await authService.fetchAuthUser() else { return false }
        if defaultManager.signUpDraft == nil {
            defaultManager.deleteDefaults()
            defaultManager.createDraftProfile(user: user)
        }
        return true
    }

    func createProfile() async throws {
        guard let signUpDraft = defaultManager.signUpDraft else { return }
        let profile = try userRepo.createUser(draft: signUpDraft)
        await session.startSession(user: profile)
    }


    func saveAndNextStep<T>(kp: WritableKeyPath<DraftProfile, T>, to value: T, updateOnly: Bool = false) {
        //1. Prevent quick double tapping logic
        if !updateOnly {
            guard canAdvance else { return }
            canAdvance = false
            Task { try? await Task.sleep(for: .milliseconds(300)) ; canAdvance = true }
        }
        
        //2. Actually move forward
        direction = .forward
        if !updateOnly { withAnimation(.transition) { defaultManager.advanceOnboarding() } }
        defaultManager.update(kp, to: value)
    }
    
    func goBackStep() {
        guard defaultManager.onboardingStep > 0 else { return }
        direction = .back
        withAnimation(.transition) {
            defaultManager.retreatOnboarding()
        }
    }
}
enum TransitionDirection { case forward, back }
