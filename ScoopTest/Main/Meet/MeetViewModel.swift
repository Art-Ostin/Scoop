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

//
//@Observable class MeetContainerViewModel {
//    
//    
//    var meetSection: MeetSections = .intro
//    
//    let dailyProfiles: DailyProfilesStore
//    let userStore: CurrentUserStore
//    
//    
//    var profiles: [ProfileViewModel] = []
//    
//    var profile1: UserProfile?
//    var profile2: UserProfile?
//    
//    
//    init(profileManager: ProfileManaging, userStore: CurrentUserStore) {
//        self.dailyProfiles = profileManager
//        self.userStore = userStore
//    }
//    
//    func loadProfiles() async {
//        profiles = dailyProfiles.load
//        
//        
//    }
//    
//    
//    
//    
//}
