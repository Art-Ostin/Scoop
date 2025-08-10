//
//  UserModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct PromptResponse: Codable  {
    let prompt: String
    let response: String
}

struct UserProfile: Codable, Equatable {
      
    let userId: String
    let email: String
    let dateCreated: Date?
    let sex: String?
    let attractedTo: String?
    let year: String?
    let height: String?
    let interests: [String]?
    let degree: String?
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
    let languages: String?
    let favouriteMovie: String?
    let favouriteSong: String?
    let favouriteBook: String?
    let character: [String]?
    let imagePath: [String]?
    let imagePathURL: [String]?
    
    //Option 1 -- method of storing events
    let userEvents: [Event]?
    
    //Option 2 -- method of storing events
    let successfulEvents: [Event]?
    let potentialEvents: [Event]?
    let declinedEvents: [Event]?
    
    
    init(auth: AuthDataResult) {
        self.userId = auth.user.uid
        self.email = auth.user.email ?? ""
        self.dateCreated = Date()
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
        self.degree = try container.decodeIfPresent(String.self, forKey: .degree)
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
        self.languages = try container.decodeIfPresent(String.self, forKey: .languages)
        self.favouriteMovie = try container.decodeIfPresent(String.self, forKey: .favouriteMovie)
        self.favouriteSong = try container.decodeIfPresent(String.self, forKey: .favouriteSong)
        self.favouriteBook = try container.decodeIfPresent(String.self, forKey: .favouriteBook)
        self.character = try container.decodeIfPresent([String].self, forKey: .character)
        self.imagePath = try container.decodeIfPresent([String].self, forKey: .imagePath)
        self.imagePathURL = try container.decodeIfPresent([String].self, forKey: .imagePathURL)
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
        try container.encodeIfPresent(self.degree, forKey: .degree)
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
        try container.encodeIfPresent(self.languages, forKey: .languages)
        try container.encodeIfPresent(self.favouriteMovie, forKey: .favouriteMovie)
        try container.encodeIfPresent(self.favouriteSong, forKey: .favouriteSong)
        try container.encodeIfPresent(self.favouriteBook, forKey: .favouriteBook)
        try container.encodeIfPresent(self.character, forKey: .character)
        try container.encodeIfPresent(self.imagePath, forKey: .imagePath)
        try container.encodeIfPresent(self.imagePathURL, forKey: .imagePathURL)
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
