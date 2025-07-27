//
//  FirestoreManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI


@Observable final class ProfileManager: ProfileManaging {
    
    
    init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createProfile (profile: UserProfile) async throws {
        try userDocument(userId: profile.userId).setData(from: profile, merge: false)
    }
    
    func getProfile(userId: String) async throws -> UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
    
    func update(userId: String, values: [UserProfile.CodingKeys: Any]) async throws {
            var data: [String: Any] = [:]
            for (key, value) in values { data[key.rawValue] = value }
            try await userDocument(userId: userId).updateData(data)
        }
    
    func updatePrompt(userId: String, promptIndex: Int, prompt: PromptResponse) async throws {
        let key: UserProfile.CodingKeys
        switch promptIndex {
        case 1: key = .prompt1
        case 2: key = .prompt2
        case 3: key = .prompt3
        default: return
        }
        let data = try Firestore.Encoder().encode(prompt)
        try await update(userId: userId, values: [key: data])
    }
}
