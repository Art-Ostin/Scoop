//
//  ProfileModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import Foundation


struct promptResponse {
    let question: String
    let answer: String
}


struct Profile {
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
    static var currentUser: Profile {
        
        if let u =  EditProfileViewModel.instance.user {

            return Profile (
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
        
    }

}





    



