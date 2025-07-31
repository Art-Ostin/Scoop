//
//  MeetTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct MeetTest: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    @State var randomProfiles: [UserProfile] = []
    
    @State private var profile1: UserProfile?
    @State private var profile2: UserProfile?
    
    
    
    @State var selectedProfile: UserProfile? = nil
        
    var body: some View {
        
        VStack {
            if let profile1 = profile1 {
                Button("showProfile") {
                    selectedProfile = profile1
                }
                
                Text(profile1.name ?? "")
                
            }
                
                
            Button("showProfile2") {
                if randomProfiles.count > 0 {
                    selectedProfile = randomProfiles[1]
                }
            }
        }
        .task {
            randomProfiles = try! await dependencies.profileManager.getRandomProfile()
            profile1 = randomProfiles[safe: 0]
            profile2 = randomProfiles[safe: 1]
        }
        .fullScreenCover(item: $selectedProfile) { profile in
            ProfileView(profile: profile)
        }
        
    }
}

#Preview {
    MeetTest()
}
