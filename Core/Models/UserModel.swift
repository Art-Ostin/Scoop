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
    var prompt1 = PromptResponse(prompt: "", response: "")
    var prompt2 = PromptResponse(prompt: "", response: "")
    
    init(user: User) {
        self.id = user.uid
        self.email = user.email ?? ""
    }
}

struct UserProfile: Codable, Equatable, Identifiable, Hashable {
    
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
    var languages: [String] = []
    var prompt1: PromptResponse
    var prompt2: PromptResponse
    var prompt3 = PromptResponse(prompt: "The dream date", response: "")
    
    var idealMeetUp: IdealMeetUp?
    var favouriteMovie: String?
    var favouriteSong: String?
    var favouriteBook: String?
    var activeCycleId: String?
    var character: [String]?
    var preferredYears: [String] = ["U0", "U1", "U2", "U3", "U4"]
    @ServerTimestamp var createdAt: Date?
    
    //Data regarding pausing/blocking User account
    var frozenUntil: Date? = nil
    var frozenReason: String? = nil
    var isFrozen: Bool {
        guard let frozenUntil else { return false }
        return frozenUntil > Date()
    }
    var blockedContext: BlockedContext? = nil
    var isBlocked: Bool = false

    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
            drugs: draft.drugs,
            prompt1: draft.prompt1,
            prompt2: draft.prompt2
        )
    }
    enum Field: String {
      case name, sex, attractedTo, year, height, interests, degree, hometown,
           nationality, lookingFor, imagePath, imagePathURL, drinking, smoking,
           marijuana, drugs, prompt1, prompt2, prompt3, languages, character,
           favouriteMovie, favouriteSong, favouriteBook, activeCycleId, idealMeetUp, preferredYears
    }
}


struct IdealMeetUp: Codable {
    let time: Date
    let place: EventLocation
    let type: EventType
    let message: String?
}
