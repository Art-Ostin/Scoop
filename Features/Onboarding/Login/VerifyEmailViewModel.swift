//
//  EmailVerificationViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 21/07/2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
@Observable class VerifyEmailViewModel {
    
    //Injected
    let session: Session
    let defaultsManager: DefaultsManaging
    let authService: AuthServicing
    let userRepo: UserRepository

    //Login form state
    var username: String = ""
    var email: String { "\(username)@mail.mcgill.ca" }
    var password: String = "HelloWorld"
    var isVerifying = false
    var showError = false

    init (session: Session, defaultsManager: DefaultsManaging, authService: AuthServicing, userRepo: UserRepository) {
        self.session = session
        self.defaultsManager = defaultsManager
        self.authService = authService
        self.userRepo = userRepo
    }

    func isValid(email: String) -> Bool {
        guard email.count > 4, let dotRange = email.range(of: ".") else {
            return false
        }
        let suffix = email[dotRange.upperBound...]
        return suffix.count >= 2
    }

    func createAuthUser (email: String, password: String) async throws {
        let authData = try await authService.createAuthUser(email: email, password: password)
        defaultsManager.createDraftProfile(user: authData.user)
    }

    func signInUser(email: String, password: String) async throws {
        try await authService.signInAuthUser(email: email, password: password)
    }

    ///Signs in (or creates) the account for a completed code, then keeps `isVerifying` true so the
    ///sheet holds its loading state until Session flips appState and RootView dismisses it.
    ///Returns false when the attempt failed and the code entry should reset.
    func verifyCode() async -> Bool {
        guard !isVerifying else { return true }
        isVerifying = true
        showError = false
        do {
            try await signInUser(email: email, password: password)
        } catch {
            do {
                try await createAuthUser(email: email, password: password)
            } catch {
                isVerifying = false
                showError = true
                return false
            }
        }
        //Failsafe: auth succeeded but the session never left .login (e.g. the profile load died) —
        //release the hold instead of spinning forever.
        try? await Task.sleep(for: .seconds(15))
        if session.appState == .login {
            isVerifying = false
            showError = true
            return false
        }
        return true
    }
}
