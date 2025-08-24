//
//  EmailVerificationViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 21/07/2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@Observable class VerifyEmailViewModel {
    
    let sessionManager: SessionManager
    let authManager: AuthManaging
    let userManager: UserManager
    
    init (sessionManager: SessionManager, authManager: AuthManaging, userManager: UserManager) {
        self.sessionManager = sessionManager
        self.authManager = authManager
        self.userManager = userManager
    }
    
    func authoriseEmail(email: String) -> Bool {
        guard email.count > 4, let dotRange = email.range(of: ".") else {
            return false
        }
        let suffix = email[dotRange.upperBound...]
        return suffix.count >= 2
    }
    
    var username: String = ""
    var email: String { "\(username)@mail.mcgill.ca" }
    var password: String = "HelloWorld"
    
    func createUser (email: String, password: String) async throws {
//        let authData = try await authManager.createAuthUser(email: email, password: password)
//        let user = try await userManager.createUser(authUser: authData)
//        await sessionManager.startSession(user: user)
    }
    
    func signInUser(email: String, password: String) async throws {
        try await authManager.signInAuthUser(email: email, password: password)
    }
}
