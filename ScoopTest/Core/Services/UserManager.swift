//
//  CurrentUserStore.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserSession {
    let user: UserProfile
}

class UserManager {
    
    private let auth: AuthManaging
    init(auth: AuthManaging) { self.auth = auth }
    
    private var userCollection: CollectionReference { Firestore.firestore().collection("users") }
    private func userDocument(userId: String) -> DocumentReference { userCollection.document(userId)}
    
    private var session: UserSession?
    var user: UserProfile {
        guard let session else { fatalError("UserSession not configured") }
        return session.user
    }
    
    func createUser (authUser: AuthDataResult) async throws {
        let uid = authUser.user.uid
        let profileUser = UserProfile(auth: authUser)
        try userDocument(userId: uid).setData(from: profileUser)
    }
    func loadUser() async throws {
        let uid = try auth.fetchAuthUser()
        let user = try await fetchUser(userId: uid)
        self.session = UserSession(user: user)
    }
    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws {
        let uid = try auth.fetchAuthUser()
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value }
        try await userDocument(userId: uid).updateData(data)
    }
    func fetchUser(userId: String) async throws -> UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
}


