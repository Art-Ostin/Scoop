//
//  UserModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


struct AuthAccount: Codable, Equatable {
    let id: String
    let email: String
    @ServerTimestamp var createdAt: Date?
    
    init(auth: AuthDataResult) {
        self.id = auth.user.uid
        self.email = auth.user.email ?? ""
        self.createdAt = nil
    }
}

struct DraftProfile {

    let id: String
    let email: String
    let createdAt: Date
    var sex: String?
    var attractedTo: String?
    var year: String?
    var height: String?
    var interests: [String]?
    var degree: String?
    var hometown: String?
    var nationality: [String]?
    var lookingFor: String?
    var imagePath: [String]?
    var imagePathURL: [String]?
    var drinking: String?
    var smoking: String?
    var marijuana: String?
    var drugs: String?
    
    init(auth: AuthAccount) {
        self.id = auth.id
        self.email = auth.email
        self.createdAt = auth.createdAt ?? Date()
        self.sex = nil
        self.attractedTo = nil
        self.year = nil
        self.height = nil
        self.interests = nil
        self.degree = nil
        self.hometown = nil
        self.nationality = nil
        self.lookingFor = nil
        self.imagePath = nil
        self.imagePathURL = nil
        self.drinking = nil
        self.smoking = nil
        self.marijuana = nil
        self.drugs = nil
    }
}


struct UserProfile: Codable, Equatable, Identifiable {
    
    let id: String
    let email: String
    let createdAt: Date
    var name: String
    var rating: Int
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
    
    var prompt1: PromptResponse?
    var prompt2: PromptResponse?
    var prompt3: PromptResponse?
    var languages: String?
    
    var character: [String]?
    var favouriteMovie: String?
    var favouriteSong: String?
    var favouriteBook: String?
    var activeCycleId: String?
    
    init(draft: DraftProfile) {
        self.id = draft.id
        self.email = draft.email
        self.createdAt = draft.createdAt
        self.name = email.components(separatedBy: ".")[0].capitalized
        self.rating = 1000
        self.sex = draft.sex ?? ""
        self.attractedTo = draft.attractedTo ?? ""
        self.year = draft.year ?? ""
        self.height = draft.height ?? ""
        self.interests = draft.interests ?? []
        self.degree = draft.degree ?? ""
        self.hometown = draft.hometown ?? ""
        self.nationality = draft.nationality ?? []
        self.lookingFor = draft.lookingFor ?? ""
        self.imagePath = draft.imagePath ?? []
        self.imagePathURL = draft.imagePathURL ?? []
        self.drinking = draft.drinking ?? ""
        self.smoking = draft.smoking ?? ""
        self.marijuana = draft.marijuana ?? ""
        self.drugs = draft.drugs ?? ""
        
        self.prompt1 = nil
        self.prompt2 = nil
        self.prompt3 = nil
        self.languages = nil
        self.character = nil
        self.favouriteMovie = nil
        self.favouriteBook = nil
        self.activeCycleId = nil
    }
    
    enum Field: String {
      case name, sex, attractedTo, year, height, interests, degree, hometown,
           nationality, lookingFor, imagePath, imagePathURL, drinking, smoking,
           marijuana, drugs, prompt1, prompt2, prompt3, languages, character,
           favouriteMovie, favouriteSong, favouriteBook, activeCycleId
    }

}

extension UserProfile {
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
}












/*
 struct ll: Codable, Equatable {
     
     
     let userId, email: String
     let dateCreated: Date
     let accountComplete: Bool
     var rating: Int
     
     var sex, attractedTo, year, degree, height, hometown, name, lookingFor, drinking,
         smoking, marijuana, drugs, languages, favouriteMovie, favouriteSong, favouriteBook, activeCycleId: String?
     
     var interests, nationality, character, imagePath, imagePathURL: [String]?

     var prompt1, prompt2, prompt3: PromptResponse?
     
     init(auth: AuthDataResult) {
         self.userId = auth.user.uid
         self.email = auth.user.email ?? ""
         self.name = email.components(separatedBy: ".")[0].capitalized
         self.dateCreated = Date()
         self.rating = 1000
         self.sex = nil // Make non optional
         self.attractedTo = nil // Make non optional
         self.year = nil // Make non optional
         self.height = nil // make non optional
         self.interests = nil // make non optional
         self.degree = nil // make non optional
         self.hometown = nil // make non optional
         self.nationality = nil // Make non optional
         self.lookingFor = nil // Make non optional
         self.imagePath = nil // Make non optional
         self.imagePathURL = nil // Make non optional
     
     
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
         case rating = "rating"
     }
 }
 

 */

