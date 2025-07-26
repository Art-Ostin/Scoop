//
//  ProfileViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 25/06/2025.
//

import Foundation
import SwiftUI


//Have this profile viewModel 
@Observable class ProfileViewModel {
    
    var profile = EditProfileViewModel.instance.user



    var showInvite: Bool = false
    var inviteSent: Bool = false
    
    //Showing Image Scrolling Page
    var imageSelection: Int = 0
    let pageSpacing: CGFloat = -48
    
    
    //Determining the ScrollView
    var startingOffsetY: CGFloat = UIScreen.main.bounds.height * 0.78
    var currentDragOffsetY: CGFloat = 0
    var endingOffsetY: CGFloat = 0
    
}


/* -- Depedency injection allows me to customise the init. 
 
 This means whenever I call the profileViewModel there is a custom init which I can then pass a value into.

 let profile: UserProfile
 
 init(profile: UserProfile = currentUser) {
    self.profile = proile
 }
 
 
 
 */


