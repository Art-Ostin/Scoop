//
//  AuthenticationManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 06/07/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI

class AuthManager: AuthManaging {

    func createAuthUser(email: String, password: String ) async throws -> AuthDataResult {
        return try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signInAuthUser(email: String, password: String ) async throws {
       try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
    }
    
    func signOutAuthUser() throws {
        try Auth.auth().signOut()
    }
    
    @discardableResult func fetchAuthUser () async -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        do {
            try await user.reload()
        } catch {
            return nil
        }
        print(user.uid)
        return Auth.auth().currentUser?.uid
    }
}
