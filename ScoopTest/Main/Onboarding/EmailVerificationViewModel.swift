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

@Observable class EmailVerificationViewModel {
    
    private let dep: AppDependencies
    init (dep: AppDependencies) { self.dep = dep }
    
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
        let authData = try await dep.authManager.createAuthUser(email: email, password: password)
        try await dep.userManager.createUser(authUser: authData)
    }
    
    func signInUser(email: String, password: String) async throws {
        try await dep.authManager.signInAuthUser(email: email, password: password)
    }
}
