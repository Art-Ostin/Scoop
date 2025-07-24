//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import Foundation
import SwiftUI


@Observable class ProfileViewModel {
    
    var profile: localProfile?
    
    var profileMatch: Profile = .sampleDailyProfile1
    var profileMatch2: Profile = .sampleDailyProfile2
    
    var showInvite: Bool = false
    var inviteSent: Bool = false
    
    //Showing Image Scrolling Page
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    
    //Determining the ScrollView
    var startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.78
    var currentDragOffsetY: CGFloat = 0
    var endingOffsetY: CGFloat = 0
    
    init() {
        
        Task { @MainActor in
            self.profile = Profile.currentUser
            
        }
    }
    
}
