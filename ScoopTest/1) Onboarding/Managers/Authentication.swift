//
//  AuthenticationManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 06/07/2025.
//

import Foundation
import FirebaseAuth


struct Account {
    
    let uid: String
    let email: String
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
    }
}

@Observable class AuthenticationManager {
    
    static let instance = AuthenticationManager()
    
    private init() {
    }
    
    func signOutUser() throws {
        try Auth.auth().signOut()
    }
    
    func createUser(email: String, password: String ) async throws -> Account {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return Account(user: authDataResult.user)
    }
    
    func signInUser(email: String, password: String ) async throws -> Account {
        let authDataResult = try await Auth.auth().signIn(with: EmailAuthProvider.credential(withEmail: email, password: password))
        return Account(user: authDataResult.user)
    }

    
    func isUserLoggedIn() throws -> Account {
        guard let authUser = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return Account(user: authUser)
    }
    
}
