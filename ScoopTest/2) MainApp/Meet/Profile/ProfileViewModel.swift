//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation

@Observable class ProfileViewModel {
    
    var profile: UserProfile
    
    var showInvite: Bool = false
    var inviteSent: Bool = false
    
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    init(profile: UserProfile) {
        self.profile = profile
    }
}
