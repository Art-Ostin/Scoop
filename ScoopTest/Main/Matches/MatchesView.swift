//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import Combine

struct MatchesView: View {
    
    @Environment(\.appState) private var appState
    
    @State var vm: MatchesViewModel
    @State var showProfileView = false
    @State var image: UIImage?
    
    init(vm: MatchesViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image("DancingCats")
                
                Text(vm.user.name ?? "No name found")
                
                
                Text("View your past Meet Ups Here")
                    .font(.body(20))
                
                ActionButton(text: "Sign Out") {
                    try? vm.authManager.signOutAuthUser()
                    appState.wrappedValue = .login
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
                            CirclePhoto(image: image ?? UIImage())
                        }
                        .onTapGesture {showProfileView = true }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showProfileView, content: {
            EditProfileContainer(vm: EditProfileViewModel(cachManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager, draftUser: vm.user))
        })
        .task {
            image = try? await vm.fetchFirstImage()
        }
    }
}
