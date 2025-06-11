//
//  Untitled.swift
//  ScoopTest
//
//  Created by Art Ostin on 31/05/2025.
//

import Foundation

enum Sex {
    case male
    case female
    case beyondBinary(String)
}

enum AttractedTo {
    case men
    case women
    case menAndWomen
    case allGenders
}

enum Year {
    case U0
    case U1
    case U2
    case U3
    case U4
}


struct Profile: Identifiable {
    let id: String = UUID().uuidString
    let email: String
    let sex: Sex
    let attractedTo: AttractedTo
    let year: Year
    let Nationality: String
    let program: String
    let hometown: String
}



struct countryData: Identifiable {
    let flag: String
    let name: String
    
    var id: String {name}
}


struct quoteContent: Identifiable {
    let quoteText: String
    let name: String
    
    var id: String {
        let firstFiveWords = quoteText
            .components(separatedBy: " ")
            .prefix(5)
            .joined(separator: " ")
        return name + firstFiveWords
    }
}
