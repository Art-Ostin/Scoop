//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//


enum MeetSections {
    case intro
    case twoDailyProfiles
    case profile
}


import SwiftUI

struct MeetContainer: View {
    
    @State private var state = MeetSections.intro
    
    var body: some View {
        
        switch state {
            
        case .intro:
            IntroView(state: $state)
            
        case .twoDailyProfiles:
            TwoDailyProfilesView(state: $state)
            
        case .profile:
            if let profile = CurrentUserStore.shared.user {
                ProfileView(profile: profile, state: $state)

            }
        }
        
    }
}

#Preview {
    MeetContainer()
}
