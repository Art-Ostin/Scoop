//
//  UserModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct DraftProfile: Codable {
    let id: String
    let email: String
    var sex = ""
    var attractedTo = ""
    var year = ""
    var height = ""
    var interests: [String] = []
    var degree = ""
    var hometown = ""
    var nationality: [String] = []
    var lookingFor = ""
    var imagePath: [String] = []
    var imagePathURL: [String] = []
    var drinking = ""
    var smoking = ""
    var marijuana = ""
    var drugs = ""
    
    init(auth: AuthDataResult) {
        self.id = auth.user.uid
        self.email = auth.user.email ?? ""
    }
}

struct UserProfile: Codable, Equatable, Identifiable {
    
    let id: String
    let email: String
    var name: String
    var rating = 1000
    var sex: String
    var attractedTo: String
    var year: String
    var height: String
    var interests: [String]
    var degree: String
    var hometown: String
    var nationality: [String]
    var lookingFor: String
    var imagePath: [String]
    var imagePathURL: [String]
    var drinking: String
    var smoking: String
    var marijuana: String
    var drugs: String
    var languages: String = ""
    
    var prompt1: PromptResponse?
    var prompt2: PromptResponse?
    var prompt3: PromptResponse?
    var favouriteMovie: String?
    var favouriteSong: String?
    var favouriteBook: String?
    var activeCycleId: String?
    var character: [String]?
    @ServerTimestamp var createdAt: Date?
}

extension UserProfile {
    
    init(draft: DraftProfile) {
        self.init(
            id: draft.id,
            email: draft.email,
            name: draft.email.split(separator: ".").first.map(String.init)?.capitalized ?? "",
            sex: draft.sex,
            attractedTo: draft.attractedTo,
            year: draft.year,
            height: draft.height,
            interests: draft.interests,
            degree: draft.degree,
            hometown: draft.hometown,
            nationality: draft.nationality,
            lookingFor: draft.lookingFor,
            imagePath: draft.imagePath,
            imagePathURL: draft.imagePathURL,
            drinking: draft.drinking,
            smoking: draft.smoking,
            marijuana: draft.marijuana,
            drugs: draft.drugs
        )
    }
    enum Field: String {
      case name, sex, attractedTo, year, height, interests, degree, hometown,
           nationality, lookingFor, imagePath, imagePathURL, drinking, smoking,
           marijuana, drugs, prompt1, prompt2, prompt3, languages, character,
           favouriteMovie, favouriteSong, favouriteBook, activeCycleId
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
}

