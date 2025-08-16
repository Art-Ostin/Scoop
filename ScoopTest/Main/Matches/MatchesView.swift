//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import Combine



struct MatchesView: View {
    
    @Environment(\.stateOfApp) private var stateOfApp
    
    
    let dependencies: AppDependencies
            
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
                    
                    Text(dependencies.userManager.user?.name ?? "No Name")
                    
                    ActionButton(text: "Sign Out") {
                        try? dependencies.authManager.signOutUser()
                        stateOfApp.wrappedValue = .login
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
                        
                        VStack {
                            CirclePhoto(image: profileImage ?? UIImage())
                        }
                        .onTapGesture {showProfileView = true }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showProfileView, content: {
            EditProfileContainer()
        })
        .task {
            let user = dependencies.userManager.user
            if let user {
                profileImage = await dependencies.cacheManager.loadProfileImages([user]).first
            }
        }
    }
}
