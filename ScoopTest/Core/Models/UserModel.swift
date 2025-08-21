//
//  UserModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct UserProfile: Codable, Equatable {
    
    let userId, email: String
    let dateCreated: Date
    let accountComplete: Bool
    let sex, attractedTo, year, height, degree, hometown, name, lookingFor, drinking,
        smoking, marijuana, drugs, languages, favouriteMovie, favouriteSong, favouriteBook, activeCycleId: String?
    let interests, nationality, character, imagePath, imagePathURL: [String]?
    let prompt1, prompt2, prompt3: PromptResponse?
    
    
    init(auth: AuthDataResult) {
        self.userId = auth.user.uid
        self.email = auth.user.email ?? ""
        self.dateCreated = Date()
        self.accountComplete = false
        self.sex = nil
        self.attractedTo = nil
        self.year = nil
        self.height = nil
        self.interests = nil
        self.degree = nil
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
        self.languages = nil
        self.favouriteMovie = nil
        self.favouriteSong = nil
        self.favouriteBook = nil
        self.character = nil
        self.imagePath = nil
        self.imagePathURL = nil
        self.activeCycleId = nil
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
        case degree = "degree"
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
        case languages = "languages"
        case favouriteMovie = "favourite_movie"
        case favouriteSong = "favourite_song"
        case favouriteBook = "favourite_book"
        case character = "character"
        case imagePath = "image_path"
        case imagePathURL = "image_path_url"
        case activeCycleId = "active_cycle_id"
        case accountComplete = "account_complete"
    }
}

extension UserProfile: Identifiable {
    var id: String { userId }
}
extension UserProfile {
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.userId == rhs.userId
    }
}
