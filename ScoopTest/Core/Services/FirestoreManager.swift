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

@Observable final class FirestoreManager: ProfileManaging {
    
    var userManager: UserManager?
    
    init(userManager: UserManager? = nil) {
        self.userManager = userManager
    }
    
    private var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createProfile (profile: UserProfile) async throws {
        try userDocument(userId: profile.userId).setData(from: profile, merge: false)
    }
    
    func getProfile(userId: String) async throws -> UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
    
    func getProfile() async throws -> UserProfile {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        return try await getProfile(userId: id)
    }
    
    func update(userId: String, values: [UserProfile.CodingKeys: Any]) async throws {
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value }
        try await userDocument(userId: userId).updateData(data)
    }
    
    func update(values: [UserProfile.CodingKeys: Any]) async throws {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        try await update(userId: id, values: values)
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
    
    func updatePrompt(promptIndex: Int, prompt: PromptResponse) async throws {
        guard let id = userManager?.user?.userId else { throw URLError(.userAuthenticationRequired) }
        try await updatePrompt(userId: id, promptIndex: promptIndex, prompt: prompt)
    }
    
    
    func currentId() -> String {
        guard let id  = userManager?.user?.userId else {return ""}
        return id
    }
    
    //Need to update this, so that it is querying on the database, and only getting the right kind of user's.
    func getRandomProfile() async throws -> [UserProfile] {
        let userId = currentId()
        let snapshot = try await userCollection.getDocuments()
        let profiles = try snapshot.documents
            .compactMap { try $0.data(as: UserProfile.self)}
            .filter { $0.id != userId }
        return Array(profiles.shuffled().prefix(2))
    }
}




