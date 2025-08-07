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

@Observable class AuthenticationManager: AuthenticationManaging {
    
    let profile: ProfileManaging
    
    init(profile: ProfileManaging) {
        self.profile = profile
    }
    
    //MOTHER FUNCTION 1  (Change the wording so its specific to the authenticated user) --
    func createUser(email: String, password: String ) async throws {
        
        //Need logic from will here to actually verify the user -- before create user function is called.
        
        //This is calling the function that creates the authenticated User.
        let authUser = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let profileUser = UserProfile(auth: authUser)
        try await profile.createProfile(profile: profileUser)
    }
    
    func signInUser(email: String, password: String ) async throws {
        let _ = try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
    }
    
    func getAuthenticatedUser () throws -> AuthenticatedUser {
        guard let authData = Auth.auth().currentUser else { throw URLError(.badServerResponse) }
        return AuthenticatedUser(user: authData)
    }
    
    func signOutUser() throws {
        try Auth.auth().signOut()
    }
}

