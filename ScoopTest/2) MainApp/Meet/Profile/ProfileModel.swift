//
//  ProfileModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import Foundation

struct Profile {
    
    var name: String = ""
    var nationality: [String]
    var images: [String]
    var year: String
    var height: String
    var passions: [String]
    var hometown: String
    var lookingFor: String
    var faculty: String
    var prompt1: promptResponse
    var prompt2: promptResponse
}

struct promptResponse {
    let question: String
    let answer: String
}


struct localProfile {
    
    var userId: String
    var email: String
    var dateCreated: Date?
    var sex: String?
    var attractedTo: String?
    var year: String?
    var height: String?
    var interests: [String]?
    var degree: String?
    var hometown: String?
    var name: String?
    var nationality: [String]?
    var lookingFor: String?
    var prompt1: PromptResponse?
    var prompt2: PromptResponse?
    var prompt3: PromptResponse?
    var drinking: String?
    var smoking: String?
    var marijuana: String?
    var drugs: String?
    var languages: String?
    var favouriteMovie: String?
    var favouriteSong: String?
    var favouriteBook: String?
    var character: [String]?
    var imagePath: [String]?
    var imagePathURL: [String]?
    
}


extension Profile {
    
    @MainActor
    static var currentUser: localProfile? {
        
        guard let u =  EditProfileViewModel.instance.user else {return nil}

            return localProfile (
                userId: u.userId,
                email: u.email,
                dateCreated: u.dateCreated,
                sex: u.sex,
                attractedTo: u.attractedTo,
                year: u.year,
                height: u.height,
                interests: u.interests,
                degree: u.degree,
                hometown: u.hometown,
                name: u.name,
                nationality: u.nationality,
                lookingFor: u.lookingFor,
                prompt1: u.prompt1,
                prompt2: u.prompt2,
                prompt3: u.prompt3,
                drinking: u.drinking,
                smoking: u.smoking,
                marijuana: u.marijuana,
                drugs: u.drugs,
                languages: u.languages,
                favouriteMovie: u.favouriteMovie,
                favouriteSong: u.favouriteSong,
                favouriteBook: u.favouriteBook,
                character: u.character,
                imagePath: u.imagePath,
                imagePathURL: u.imagePathURL)
            
    }
    
    static let sampleMe = Profile(
        
        name: "Arthur",
        nationality: ["French"],
        images: ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"],
        year: "U3",
        height: "193 cm",
        passions: ["Coding SwiftUI", "Running 5Ks", "Blender Animations", "Political Philosophy", "Healthy Meal Prepping"],
        hometown: "London",
        lookingFor: "Meaningful meetups",
        faculty: "Faculty of Arts",
        prompt1: promptResponse(
            question: "You’ll just have to meet me to find out about…",
            answer: "What it takes to build a dating app from scratch"
        ),
        prompt2: promptResponse(
            question: "Would you rather be a pear or an orange. Why?",
            answer: "Orange — round, bright, and good with breakfast"
        )
    )
    
    
    static let sampleMatch = Profile(
        name: "Leila",
        nationality: ["🇨🇦", "🇲🇦"],
        images: ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"],
        year: "U2",
        height: "168 cm",
        passions: ["Ceramics", "Jazz Piano", "Foraging", "Contemporary Dance"],
        hometown: "Vancouver",
        lookingFor: "Casual",
        faculty: "Faculty of Science",
        prompt1: promptResponse(
            question: "You’ll just have to meet me to find out about…",
            answer: "My theory that pigeons are secretly surveillance drones"
        ),
        prompt2: promptResponse(
            question: "Would you rather be a pear or an orange. Why?",
            answer: "Pear. Underrated, a bit awkward, but unforgettable."
        )
    )
    
    static let sampleDailyProfile1 = Profile(
        name: "Alex",
        nationality: ["🇬🇧", "🇫🇷"],
        images: ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"],
        year: "U3",
        height: "183 cm",
        passions: ["Rock Climbing", "Cooking", "Synth Music", "Chess"],
        hometown: "London",
        lookingFor: "Genuine connections",
        faculty: "Faculty of Arts",
        prompt1: promptResponse(
            question: "You’ll just have to meet me to find out about…",
            answer: "My talent for solving Rubik’s cubes one-handed"
        ),
        prompt2: promptResponse(
            question: "Would you rather be a pear or an orange. Why?",
            answer: "Orange. Zesty, social, and a little bit tangy."
        )
    )
    
    static let sampleDailyProfile2 = Profile(
        name: "Maya",
        nationality: ["🇯🇵", "🇨🇦"],
        images: ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"],
        year: "U1",
        height: "162 cm",
        passions: ["Photography", "Salsa Dancing", "Baking", "Poetry"],
        hometown: "Toronto",
        lookingFor: "Someone to go on museum dates with",
        faculty: "Faculty of Engineering",
        prompt1: promptResponse(
            question: "You’ll just have to meet me to find out about…",
            answer: "My secret collection of vintage cameras"
        ),
        prompt2: promptResponse(
            question: "Would you rather be a pear or an orange. Why?",
            answer: "Pear. Sweet, subtle, and full of surprises."
        )
    )
}





    



