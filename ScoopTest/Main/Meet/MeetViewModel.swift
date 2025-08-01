//
//  MeetViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 01/08/2025.
//

import Foundation


enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile
}


@Observable class MeetViewModel {
    
    var mode: MeetSections = .intro
    
    let p1: UserProfile
    let p2: UserProfile
    
    init(p1: UserProfile, p2: UserProfile) {
        self.p1 = p1
        self.p2 = p2
    }
    
    func theHello() { print("Hello World")}
    
}
