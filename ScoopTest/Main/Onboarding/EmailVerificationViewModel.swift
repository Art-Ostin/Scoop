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
    
    
    private let authManager: AuthenticationManaging
    
    init (authManager: AuthenticationManaging) {
        self.authManager = authManager
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
        try await authManager.createUser(email: email, password: password)
    }
    
    //Also need to put in logic to authenticate. 
    func signInUser(email: String, password: String) async throws {
        //Put all the logic here to verify the user, then the function below actually sings the user in (after all verification)
        try await authManager.signInUser(email: email, password: password)
    }
}
