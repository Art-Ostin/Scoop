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
    
    @State var randomProfile: UserProfile?
    
    
    var body: some View {
        
        VStack {
            Button("Show Profile") {
                showProfile = true
            }
        }
        .task {
            randomProfile = try? await dependencies.profileManager.getRandomProfile()
        }
        
        .fullScreenCover(isPresented: $showProfile) {
            if let randomProfile = randomProfile {
                ProfileView(profile: randomProfile)
            }
        }
    }
}

#Preview {
    MeetTest()
}
