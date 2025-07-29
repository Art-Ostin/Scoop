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
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @State private var state: MeetSections? = MeetSections.intro
    
    var body: some View {
        
        switch state {
            
        case .intro:
            IntroView(state: $state)
            
        case .twoDailyProfiles:
            TwoDailyProfilesView(state: $state)
            
        case .profile:
            if let profile = dependencies.userStore.user {
                ProfileView(profile: profile, state: $state)
            }
        default: EmptyView()
        }
    }
}

#Preview {
    MeetContainer()
}
