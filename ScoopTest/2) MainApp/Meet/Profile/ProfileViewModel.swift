//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import Foundation



@Observable class ProfileViewModel {
    
    var profile = Profile (
        name: "Arthur",
        nationality: ["🇬🇧", "🇸🇪"],
        images: ["Image1", "Image2", "Image3", "Image4", "Image5", "Image6"],
        year: "U3",
        height: "193 cm",
        passions: ["Astrophysics", "Cold Water Swimming", "Music Production", "Historical Geology"],
        hometown: "London",
        lookingFor: "Casual",
        faculty: "Faculty of Arts"
    )
    
    
    
    
    
}
