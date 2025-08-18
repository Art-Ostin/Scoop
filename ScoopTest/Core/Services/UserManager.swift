//
//  CurrentUserStore.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class UserManager {
    
    @ObservationIgnored private let auth: AuthenticationManaging
    @ObservationIgnored private let profileManager: ProfileManaging
    
    init(auth: AuthenticationManaging, profileManager: ProfileManaging) {
        self.auth = auth
        self.profileManager = profileManager
    }
    
    private(set) var user: UserProfile? = nil
    
    
    private var userCollection: CollectionReference { Firestore.firestore().collection("users") }
    private func userDocument(userId: String) -> DocumentReference { userCollection.document(userId)}
    
    
    
    @MainActor
    func loadUser() async throws {
        let uid = try auth.getAuthenticatedUser().uid
        let profile = try await profileManager.getProfile(userId: uid)
        self.user = profile
    }
    
    func updateUser(values: [UserProfile.CodingKeys : Any]) async throws {
        let uid = try auth.getAuthenticatedUser().uid
        var data: [String: Any] = [:]
        for (key, value) in values { data[key.rawValue] = value }
        try await userDocument(userId: uid).updateData(data)
        try? await loadUser()
    }
    
    func updateUserPrompt(index: Int, prompt: PromptResponse) async throws {
        let uid = try auth.getAuthenticatedUser().uid
        let key: UserProfile.CodingKeys
        switch index {
        case 1: key = .prompt1
        case 2: key = .prompt2
        case 3: key = .prompt3
        default: return
        }
        let encoded = try Firestore.Encoder().encode(prompt)
        try await profileManager.update(userId: uid, values: [key: encoded])
    }
}







/*
 
     func updateCurrentUserPrompt(index: Int, prompt: PromptResponse) async throws {
         let uid = try auth.getAuthenticatedUser().uid
         try await profileManager.updatePrompt(userId: uid, promptIndex: index, prompt: prompt)
         try? await loadUser()
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
 
 */
