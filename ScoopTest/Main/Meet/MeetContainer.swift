//
//  MeetContainerView.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/06/2025.
//


import SwiftUI

struct MeetContainer: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    

    @State private var state: MeetSections? = MeetSections.intro
    
    
    @State var randomProfiles: [UserProfile] = []
    
    @State private var profile1: UserProfile?
    @State private var profile2: UserProfile?
    
    
        
    var body: some View {
        
        ZStack {
            
            switch state {
                
            case .intro:
                IntroView(state: $state)
                
            case .twoDailyProfiles:
                
                if let profile1, let profile2 {
                    TwoDailyProfilesView(state: $state, profile1: profile1, profile2: profile2)
                }
            case .profile:
                if let profile = dependencies.userStore.user {
                    ProfileView(profile: profile, state: $state)
                }
            default: EmptyView()
            }

        }.task {
            await dependencies.dailyProfiles.load()
            let profiles = dependencies.dailyProfiles.profiles
            profile1 = profiles[safe: 0]
            profile2 = profiles[safe: 1]
        }
    }
}

#Preview {
    MeetContainer()
}
