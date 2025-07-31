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
    
    @State var selectedProfile: UserProfile? = nil
        
    var body: some View {
        
        VStack {
            Button("showProfile") {
                if randomProfiles.count > 0 {
                    selectedProfile = randomProfiles[0]
                }
            }
            
            if !randomProfiles.isEmpty {
                Text(randomProfiles[0].name ?? "")
            }
            
            

            Button("showProfile2") {
                if randomProfiles.count > 0 {
                    selectedProfile = randomProfiles[1]
                }
            }
        }
        .task {
                randomProfiles = try! await dependencies.profileManager.getRandomProfile()
        }
        .fullScreenCover(item: $selectedProfile) { profile in
            ProfileView(profile: profile)
        }
        
    }
}

#Preview {
    MeetTest()
}
