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
        try await AuthenticationManager.instance.createUser(email: email, password: password)
    }
    func signInUser(email: String, password: String) async throws {
        try await AuthenticationManager.instance.signInUser(email: email, password: password)
    }
}
