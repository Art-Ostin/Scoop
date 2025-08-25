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
    @Environment(\.appDependencies) private var dep
    
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
                
                Text(vm.user.name)

                Text("View your past Meet Ups Here")
                    .font(.body(20))
                
                ActionButton(text: "Sign Out") {
                    try? vm.authManager.signOutAuthUser()
                    vm.defaultsManager.deleteDefaults()
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
            EditProfileContainer(vm: EditProfileViewModel(cacheManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager, draftUser: vm.user, defaults: dep.defaultsManager))
        })
        .task {
            do {
                image = try await vm.fetchFirstImage()
            } catch {
                print(error)
            }
        }
    }
}
