//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation



@Observable class MeetUpViewModel2 {
    
    var dep: AppDependencies
    
    var shownProfiles: [UserProfile] = []
    
    init(dep: AppDependencies) {
        self.dep = dep
    }
    
    
    func getTwoDailyProfiles() async {
        let profiles = try? await dep.profileManager.getRandomProfile()
        if let profiles {
            for profile in profiles {
                guard !shownProfiles.contains(where: { $0.id == profile.id }) else {
                    return
                }
                shownProfiles.append(profile)
            }
        }
    }
}
