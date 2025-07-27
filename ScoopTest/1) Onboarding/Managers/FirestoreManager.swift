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
    
    func getProfile(userId: String) async throws ->  UserProfile {
        try await userDocument(userId: userId).getDocument(as: UserProfile.self)
    }
    
    func updateSex(userId: String, sex: String) {
        Task {
            let data: [String: Any] = [ UserProfile.CodingKeys.sex.rawValue: sex]
            try? await userDocument(userId: userId).updateData(data)
        }
    }

    
    
    
    func updateAttractedTo(userId: String, attractedTo: String) async throws {
        let data: [String: Any] = [UserProfile.CodingKeys.attractedTo.rawValue: attractedTo]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateYear(userId: String, year: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.year.rawValue: year
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateHeight(userId: String, height: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.height.rawValue: height
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateInterests(userId: String, interest: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.interests.rawValue: FieldValue.arrayUnion([interest])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeInterests(userId: String, interest: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.interests.rawValue: FieldValue.arrayRemove([interest])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateDegree(userId: String, degree: String) async throws {
        
        let data: [String: Any] = [
            UserProfile.CodingKeys.degree.rawValue: degree
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateHometown(userId: String, hometown: String) async throws {
        
        let data: [String: Any] = [
            UserProfile.CodingKeys.hometown.rawValue: hometown
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateName(userId: String, name: String) async throws {
        
        let data: [String: Any] = [
            UserProfile.CodingKeys.name.rawValue : name
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateNationality(userId: String, nationality: String) async throws {
        let data: [String: Any] = [
            
            UserProfile.CodingKeys.nationality.rawValue: FieldValue.arrayUnion([nationality])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeNationality(userId: String, nationality: String) async throws {
        let data: [String: Any] = [
            
            UserProfile.CodingKeys.nationality.rawValue: FieldValue.arrayRemove([nationality])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateLookingFor(userId: String, lookingFor: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.lookingFor.rawValue : lookingFor
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updatePrompt(userId: String, promptIndex: Int, prompt: PromptResponse) async throws {
        guard (1...3).contains(promptIndex) else {throw URLError(.badURL)}
        let data = try Firestore.Encoder().encode(prompt)
        let key = "prompt\(promptIndex)"
        try await userDocument(userId: userId).updateData([ key: data ])
    }
    
    func updateDrinking(userId: String, drinking: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.drinking.rawValue : drinking
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateSmoking(userId: String, smoking: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.smoking.rawValue : smoking
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateMarijuana(userId: String, marijuana: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.marijuana.rawValue : marijuana
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateDrugs(userId: String, drugs: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.drugs.rawValue : drugs
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateLanguages(userId: String, languages: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.languages.rawValue : languages
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateFavouriteMovie(userId: String, favouriteMovie: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.favouriteMovie.rawValue : favouriteMovie
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateFavouriteSong(userId: String, favouriteSong: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.favouriteSong.rawValue : favouriteSong
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateFavouriteBook(userId: String, favouriteBook: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.favouriteBook.rawValue : favouriteBook
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateCharacter(userId: String, character: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.character.rawValue: FieldValue.arrayUnion([character])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeCharacter(userId: String, character: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.character.rawValue: FieldValue.arrayRemove([character])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateImagePath(userId: String, path: String, url: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.imagePath.rawValue : FieldValue.arrayUnion([path]),
            UserProfile.CodingKeys.imagePathURL.rawValue : FieldValue.arrayUnion([url])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeImagePath(userId: String, path: String, url: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.imagePath.rawValue : FieldValue.arrayRemove([path]),
            UserProfile.CodingKeys.imagePathURL.rawValue : FieldValue.arrayRemove([url])
        ]
        try await userDocument(userId: userId).updateData(data)
    }
}
