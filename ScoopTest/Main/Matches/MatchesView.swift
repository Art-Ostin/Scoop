//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI



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
                        dependencies.userStore.clearUser()
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
                        Text("View Profile")
//                        profileButton
                            .onTapGesture {
                                showProfileView = true
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

extension MatchesView {
    
    private var profileButton: some View {
        Group {
            if
                let raw = dependencies.userStore.user?.imagePath?[0],
                let url = URL(string: raw)
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Text("Profile")
            }
        }
    }
}
