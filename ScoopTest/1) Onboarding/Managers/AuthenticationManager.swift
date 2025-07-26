//
//  AuthenticationManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 06/07/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI
import Combine


struct AuthenticatedUser {
    
    let uid: String
    let email: String
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
    }
}

@Observable class AuthenticationManager: AuthenticationManaging {
    
    static let instance = AuthenticationManager()
    
    func createUser(email: String, password: String ) async throws {
        let authUser = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let profileUser = UserProfile(auth: authUser)
        try await ProfileManager.instance.createProfile(profile: profileUser)
    }
    
    func signInUser(email: String, password: String ) async throws {
        let authUser = try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
        
        let profile = UserProfile(auth: authUser)
        try await ProfileManager.instance.createProfile(profile: profile)
    }
    
    func getAuthenticatedUser () throws -> AuthenticatedUser {
        guard let authData = Auth.auth().currentUser else { throw URLError(.badServerResponse) }
        return AuthenticatedUser(user: authData)
    }
    
    func signOutUser() throws {
        try Auth.auth().signOut()
    }
    
}

