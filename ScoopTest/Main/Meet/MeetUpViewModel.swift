//
//  MeetUpViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import Foundation



@Observable class MeetUpViewModel2 {
    
    var dependencies: AppDependencies
    
    var shownProfiles: [UserProfile] = []
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }
    
    
    func fetchTwoDailyProfiles() async {
        let profiles = try? await dependencies.profileManager.getRandomProfile()
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
