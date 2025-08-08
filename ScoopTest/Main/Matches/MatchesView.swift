//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import Combine



struct MatchesView: View {
    
    @Environment(\.appDependencies) private var dependencies: AppDependencies
    
    @Binding var showLogin: Bool
    
    @State var showProfileView = false
    
    @State var profileImage: UIImage?
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 32) {
                    Image("DancingCats")
                    
                    Text("View your past Meet Ups Here")
                        .font(.body(20))
                    
                    Text(dependencies.userStore.user?.name ?? "No Name")
                    
                    ActionButton(text: "Sign Out") {
                        try? dependencies.authManager.signOutUser()
                        showLogin = true
                    }
                }
                .navigationTitle("Matches")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: 32) {
                            Image("GearIcon")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        CirclePhoto(image: profileImage ?? UIImage())
                            .onTapGesture {showProfileView = true }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showProfileView, content: {
            EditProfileContainer()
        })
        .task {
            let user = dependencies.userStore.user
            if let user {
                profileImage = await dependencies.imageCache.loadProfile([user]).first
            }
        }
    }
}

#Preview {
    MatchesView(showLogin: .constant(false))
}
