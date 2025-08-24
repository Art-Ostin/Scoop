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

    func createAuthUser(email: String, password: String ) async throws -> AuthUser {
        let dataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthUser(auth: dataResult)
    }
    
    func signInAuthUser(email: String, password: String ) async throws {
       try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
    }
    
    func signOutAuthUser() throws {
        try Auth.auth().signOut()
    }
    
    @discardableResult func fetchAuthUser () -> String? {
        guard let authData = Auth.auth().currentUser else { return nil }
        return authData.uid
    }
            
    private func createAuth() async throws {
        
    }
    
}

