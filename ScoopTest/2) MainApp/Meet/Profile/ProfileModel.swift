//
//  ProfileModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.

import Foundation








    static var currentUser: UserProfile {
        
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





    



