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
    
    @discardableResult func fetchAuthUser () async -> User? {
        guard let user = Auth.auth().currentUser else { return nil }
        try? await user.reload()
        return Auth.auth().currentUser
    }
    
    //Need to reauthenticate then delete user
    func deleteAuthUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        let cred = EmailAuthProvider.credential(withEmail: user.email!, password: "HelloWorld")
        do {
            try await user.reauthenticate(with: cred)
            try await user.delete()
        } catch {
            print(error)
        }
    }
    
    func authStateStream() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}
