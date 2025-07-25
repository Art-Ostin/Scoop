//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI


@Observable class MatchesViewModel {
    
    func signOut() throws {
        try AuthenticationManager.instance.signOutUser()
    }
}

struct MatchesView: View {
    
    @State var vm = MatchesViewModel()
    
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
                    
                    Text(EditProfileViewModel.instance.user?.name ?? "No Name")
                    
                    ActionButton(text: "Sign Out") {
                        try? vm.signOut()
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
                        ProfileButton
                            .onTapGesture {
                                showProfileView = true
                            }
                    }
                }
            }
            .fullScreenCover(isPresented: $showProfileView, content: {
                EditProfileView()
            })
        }
    }
}

#Preview {
    MatchesView(showLogin: .constant(false))
}

extension MatchesView {
    
    private var ProfileButton: some View {
        HStack (spacing: 18) {
            
            Text("Open ProfileView")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 30, height: 30)
//                .clipShape(Circle())
//                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
            
        }
    }
}
