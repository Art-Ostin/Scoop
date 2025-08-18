//
//  AuthenticationManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 06/07/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI


struct AuthenticatedUser {
    
    let uid: String
    let email: String
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
    }
}

@Observable class AuthManager: AuthManaging {
    let userManager: UserManager
    
    init(userManager: UserManager) { self.userManager = userManager }
    
    func createAuthUser(email: String, password: String ) async throws {
        let authUser = try await Auth.auth().createUser(withEmail: email, password: password)
        let profileUser = UserProfile(auth: authUser)
        try await userManager.createProfile(profile: profileUser)
    }
    
    func signInAuthUser(email: String, password: String ) async throws {
       try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
    }
    
    @discardableResult
    func fetchAuthUser () throws -> AuthenticatedUser {
        guard let authData = Auth.auth().currentUser else { throw URLError(.badServerResponse) }
        return AuthenticatedUser(user: authData)
    }
    func signOutAuthUser() throws {
        try Auth.auth().signOut()
    }
}

