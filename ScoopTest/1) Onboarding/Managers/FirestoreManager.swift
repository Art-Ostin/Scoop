//
//  FirestoreManager.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


struct PromptResponse: Codable  {
    let prompt: String
    let response: String
}


struct UserProfile: Codable {
    
    let userId: String
    let email: String
    let dateCreated: Date?
    let sex: String?
    let attractedTo: String?
    let year: String?
    let height: String?
    let interests: [String]?
    let faculty: String?
    let hometown: String?
    let name: String?
    let nationality: [String]?
    let lookingFor: String?
    let prompt1: PromptResponse?
    let prompt2: PromptResponse?
    let prompt3: PromptResponse?
    let drinking: String?
    let smoking: String?
    let marijuana: String?
    let drugs: String?
    

    init(auth: AuthDataResult) {
        self.userId = auth.user.uid
        self.email = auth.user.email ?? ""
        self.dateCreated = Date()
        self.sex = nil
        self.attractedTo = nil
        self.year = nil
        self.height = nil
        self.interests = nil
        self.faculty = nil
        self.hometown = nil
        self.name = email.components(separatedBy: ".")[0].capitalized
        self.nationality = nil
        self.lookingFor = nil
        self.prompt1 = nil
        self.prompt2 = nil
        self.prompt3 = nil
        self.drinking = nil
        self.smoking = nil
        self.marijuana = nil
        self.drugs = nil
    }
      
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email = "email"
        case dateCreated = "date_created"
        case sex = "sex"
        case attractedTo = "attracted_to"
        case year = "year"
        case height = "height"
        case interests = "interests"
        case faculty = "faculty"
        case hometown = "hometown"
        case name = "name"
        case nationality = "nationality"
        case lookingFor = "lookingFor"
        case prompt1 = "prompt1"
        case prompt2 = "prompt2"
        case prompt3 = "prompt3"
        case drinking = "drinking"
        case smoking = "smoking"
        case marijuana = "marijuana"
        case drugs = "drugs"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.email = try container.decode(String.self, forKey: .email)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.sex = try container.decodeIfPresent(String.self, forKey: .sex)
        self.attractedTo = try container.decodeIfPresent(String.self, forKey: .attractedTo)
        self.year = try container.decodeIfPresent(String.self, forKey: .year)
        self.height = try container.decodeIfPresent(String.self, forKey: .height)
        self.interests = try container.decodeIfPresent([String].self, forKey: .interests)
        self.faculty = try container.decodeIfPresent(String.self, forKey: .faculty)
        self.hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.nationality = try container.decodeIfPresent([String].self, forKey: .nationality)
        self.lookingFor = try container.decodeIfPresent(String.self, forKey: .lookingFor)
        self.prompt1 = try container.decodeIfPresent(PromptResponse.self, forKey: .prompt1)
        self.prompt2 = try container.decodeIfPresent(PromptResponse.self, forKey: .prompt2)
        self.prompt3 = try container.decodeIfPresent(PromptResponse.self, forKey: .prompt3)
        self.drinking = try container.decodeIfPresent(String.self, forKey: .drinking)
        self.smoking = try container.decodeIfPresent(String.self, forKey: .smoking)
        self.marijuana = try container.decodeIfPresent(String.self, forKey: .marijuana)
        self.drugs = try container.decodeIfPresent(String.self, forKey: .drugs)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encode(self.email, forKey: .email)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.sex, forKey: .sex)
        try container.encodeIfPresent(self.attractedTo, forKey: .attractedTo)
        try container.encodeIfPresent(self.year, forKey: .year)
        try container.encodeIfPresent(self.height, forKey: .height)
        try container.encodeIfPresent(self.interests, forKey: .interests)
        try container.encodeIfPresent(self.faculty, forKey: .faculty)
        try container.encodeIfPresent(self.hometown, forKey: .hometown)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.nationality, forKey: .nationality)
        try container.encodeIfPresent(self.lookingFor, forKey: .lookingFor)
        try container.encodeIfPresent(self.prompt1, forKey: .prompt1)
        try container.encodeIfPresent(self.prompt2, forKey: .prompt2)
        try container.encodeIfPresent(self.prompt3, forKey: .prompt3)
        try container.encodeIfPresent(self.drinking, forKey: .drinking)
        try container.encodeIfPresent(self.smoking, forKey: .smoking)
        try container.encodeIfPresent(self.marijuana, forKey: .marijuana)
        try container.encodeIfPresent(self.drugs, forKey: .drugs)
    }
}
  
final class ProfileManager {
    
    static let instance = ProfileManager ()
    
    private init () {}
    
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
    
    func updateSex(userId: String, sex: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.sex.rawValue: sex
        ]
        try await userDocument(userId: userId).updateData(data)
    }
    
    
    func updateAttractedTo(userId: String, attractedTo: String) async throws {
        let data: [String: Any] = [
            UserProfile.CodingKeys.attractedTo.rawValue: attractedTo
        ]
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
    
    func updateFaculty(userId: String, faculty: String) async throws {
        
        let data: [String: Any] = [
            UserProfile.CodingKeys.faculty.rawValue: faculty
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
}
