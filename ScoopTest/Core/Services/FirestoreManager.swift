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
    
    private let userCollection = Firestore.firestore().collection("users")
    
    
    private func userEventCollection (userId: String) -> CollectionReference {
        userCollection.document(userId).collection("user_events")
    }
    
    private func userEventDocument (userId: String, userEventId: String) -> DocumentReference {
        userEventCollection(userId: userId).document(userEventId)
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
    
    
    func addUserEvent(userId: String, event: Event) async throws {
        
        let ids: [String] = [(event.initiatorId ?? ""), (event.recipientId ?? "") ]
        let otherUserId = ids.filter { $0 != userId }.first ?? ""
        
        let role: EdgeRole
        
        if event.initiatorId == userId {
            role = .sent
        } else if event.recipientId == userId {
            role = .received
        }
        let status: EventStatus = .pending
        
        
        

        let otherUserPhotoUrl
        
        
        
        
        
        
        
        
        let data: [String: Any] =  [
            UserEvents.CodingKeys.eventId.rawValue : event.id ?? "",
            UserEvents.CodingKeys.otherUserId.rawValue : otherUserId,
            UserEvents.CodingKeys.role.rawValue : role,
            UserEvents.CodingKeys.status.rawValue : event.status,
            UserEvents.CodingKeys.eventTime.rawValue : event.time ?? Date(),
            UserEvents.CodingKeys.eventType.rawValue : event.type ?? "",
            UserEvents.CodingKeys.eventType.rawValue : event.message,
            UserEvents.CodingKeys.otherUserPhoto.rawValue :
            
            
            
        ]
        
        
        enum CodingKeys: String, CodingKey {
            case eventId = "event_id"
            case otherUserId = "other_user_id"
            case role = "role"
            case status = "status"
            case eventTime = "event_time"
            case eventType = "event_type"
            case eventMessage = "event_message"
            case eventPlace = "event_place"
            case otherUserPhoto = "other_user_photo"
            case updatedAt = "updated_at"
        }

        
        try await userEventCollection(userId: userId).document(event.id)
    }
    
    func removeUserEvent(userId: String, userEventId: String) async throws {
        try await userEventDocument(userId: userId, userEventId: userEventId).delete()
    }
    //
    //    func getAllUserEvets(userId: String) async throws -> [Event] {
    //        try await userEventCollection(userId: userId).getDocuments(as: )
    //    }
    
    //Need to update this, so that it is querying on the database, and only getting the right kind of user's.
    func getRandomProfile() async throws -> [UserProfile] {
        let snapshot = try await userCollection.getDocuments()
        let profiles = try snapshot.documents.compactMap { try $0.data(as: UserProfile.self)
        }
        return Array(profiles.shuffled().prefix(2))
    }
}




