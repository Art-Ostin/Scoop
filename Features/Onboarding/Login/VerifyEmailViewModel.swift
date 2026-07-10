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
}
