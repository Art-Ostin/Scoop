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
    
    
    let dep: AppDependencies
            
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
                    
                    Text(dep.userManager.user.name ?? "No Name")
                    
                    ActionButton(text: "Sign Out") {
                        try? dep.authManager.signOutAuthUser()
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
            let user = dep.userManager.user
            profileImage = await dep.cacheManager.loadProfileImages([user]).first
        }
    }
}
