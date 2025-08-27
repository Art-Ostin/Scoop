//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI


struct MatchesView: View {
    
    @Environment(\.appState) private var appState
    
    @State var vm: MatchesViewModel
    @State var showProfileView = false
    @State var image: UIImage?
    @State var showSettingsView = false
    
    init(vm: MatchesViewModel) { _vm = State(initialValue: vm)}

    var body: some View {
                
        NavigationStack {
            VStack(spacing: 32) {
                Image("DancingCats")
                
                Text(vm.user.name)

                Text("View your past Meet Ups Here")
                    .font(.body(20))
                

                
                
                
                
                .navigationTitle("Matches")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: 32) {
                            Image("GearIcon")
                                .onTapGesture {
                                    showSettingsView.toggle()
                            }
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
        .fullScreenCover(isPresented: $showProfileView){
            EditProfileContainer(vm: EditProfileViewModel(cacheManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager, draftUser: vm.user, defaults: vm.defaultsManager))
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsContainer(vm: SettingsViewModel(authManager: vm.authManager))
        }        
        
        
        
        
        .task(id: vm.user) {
            do {
                image = try await vm.fetchFirstImage()
            } catch {
                print(error)
            }
        }
    }
}
