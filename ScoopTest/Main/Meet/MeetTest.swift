//
//  MeetTest.swift
//  ScoopTest
//
//  Created by Art Ostin on 29/07/2025.
//

import SwiftUI

struct MeetTest: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    
    @State var showProfile: Bool = false
    @State var showProfile2: Bool = false

    
    @State var randomProfile: [UserProfile] = []
    
    
    var body: some View {
        
        VStack {
            Button("showProfile") {
                showProfile.toggle()
            }
            
            Button("showProfile") {
                showProfile2.toggle()
            }
            
            
        }
        .task {
            do {
                randomProfile = try await dependencies.profileManager.getRandomProfile()
            } catch {
                print("failed to load:", error)
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(profile: randomProfile[0])
        }
        .fullScreenCover(isPresented: $showProfile2) {
            ProfileView(profile: randomProfile[1])
        }
    }
}

#Preview {
    MeetTest()
}
