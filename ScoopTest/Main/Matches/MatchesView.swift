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
                        if let raw = dependencies.userStore.user?.imagePathURL?[0], let url = URL(string: raw) {
                            CirclePhoto(url: url)
                                .onTapGesture {showProfileView = true }
                            Text("Hello")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showProfileView, content: {
                    EditProfileContainer()
            })
        }
    }
}

#Preview {
    MatchesView(showLogin: .constant(false))
}
