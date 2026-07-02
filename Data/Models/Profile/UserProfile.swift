//
//  UserModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseFirestore


struct UserProfile: Codable, Identifiable, Equatable, Hashable {

    //1. Identifiable Information
    let id: String
    let email: String
    
    //2. CoreInfo
    var name: String
    var sex: String
    var year: String
    var height: String
    var nationality: [String]
    var lookingFor: String
    var degree: String
    
    //3. Extra Info
    var hometown: String
    var interests: [String]
    var languages: [String] = []
    var prompt1: PromptResponse
    var prompt2: PromptResponse
    var prompt3 = PromptResponse(prompt: "The dream date", response: "")
    
    //4. Vices & Media
    var drinking: String
    var smoking: String
    var marijuana: String
    var drugs: String
    var favouriteMovie: String?
    var favouriteSong: String?
    var favouriteBook: String?
    
    //5. Image Data
    var imagePath: [String]
    var imagePathURL: [String]
    
    //6. Dating Preferences
    var attractedTo: String
    var preferredYears: [String] = ["U0", "U1", "U2", "U3", "U4"]

    //7. Blocked & Frozen Data
    var frozenUntil: Date? = nil
    var cancelCount: Int = 0
    var blockedContext: BlockedContext? = nil
    var isBlocked: Bool = false

    //8. Profile MetaData
    var rating = 1000
    @ServerTimestamp var createdAt: Date?
    
    init(draft: DraftProfile) {
        self.id = draft.id
        self.email = draft.email
        self.name = draft.email.split(separator: ".").first.map(String.init)?.capitalized ?? ""
        self.sex = draft.sex
        self.attractedTo = draft.attractedTo
        self.year = draft.year
        self.height = draft.height
        self.nationality = draft.nationality
        self.lookingFor = draft.lookingFor
        self.degree = draft.degree

        self.hometown = draft.hometown
        self.interests = draft.interests
        self.imagePath = draft.imagePath
        self.imagePathURL = draft.imagePathURL

        self.drinking = draft.drinking
        self.smoking = draft.smoking
        self.marijuana = draft.marijuana
        self.drugs = draft.drugs

        self.prompt1 = draft.prompt1
        self.prompt2 = draft.prompt2
    }
}

//Firestore field names (used for update/query keys to avoid typos).
extension UserProfile {
    enum Field: String {
        case name, sex, attractedTo, year, height, interests, degree, hometown,
             nationality, lookingFor, imagePath, imagePathURL, drinking, smoking,
             marijuana, drugs, prompt1, prompt2, prompt3, languages,
             favouriteMovie, favouriteSong, favouriteBook,
             preferredYears, cancelCount, frozenUntil, blockedContext, isBlocked, rating, createdAt
    }
}

//Functions to get equatable and hashable protocol
extension UserProfile {
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
