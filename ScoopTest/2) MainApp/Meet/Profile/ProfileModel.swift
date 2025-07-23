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


extension Profile {
    
    
    
    
    
    
    
    
    
    
    static let sampleMe = Profile(
      name: "Arthur",
      nationality: ["🇬🇧", "🇸🇪"],
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



