//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import FirebaseFunctions


struct MatchesView: View {
    
    @Environment(\.appState) private var appState
    
    @State var vm: MatchesViewModel
    @State var showProfileView = false
    @State var image: UIImage?
    @State var showSettingsView = false
    init(vm: MatchesViewModel) { _vm = State(initialValue: vm)}
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.events.isEmpty {
                    noMatchesView
                } else {
                    VStack(spacing: 32) {
                        
                        Text("HEllo World")
                        ForEach(vm.events) {profileModel in
                            Text(profileModel.event?.otherUserName ?? "There was no name")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 32) {
                        Image("GearIcon")
                            .onTapGesture { showSettingsView.toggle() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    VStack {
                        CirclePhoto(image: image ?? UIImage())
                    }
                    .onTapGesture {showProfileView = true }
                }
            }
            .navigationTitle("Matches")
        }
        .fullScreenCover(isPresented: $showProfileView){
            EditProfileContainer(vm: EditProfileViewModel(cacheManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager, draftUser: vm.user, defaults: vm.defaultsManager))
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))
        }
        .task(id: vm.user) {  image = try? await vm.fetchFirstImage()}
    }
}

extension MatchesView {

    private var noMatchesView: some View {
        VStack(spacing: 32) {
            
            ActionButton(text: "Test Functions") {
                Task {
                    do{
                       let result = try await Functions.functions().httpsCallable("addmessage").call()
                        
                        let string = result.data as? String ?? "No data"
                        
                        print(string)
                    }
                }
            }
            
            Image("DancingCats")
            
            Text("View your past Meet Ups Here")
                .font(.body(20))
        }
        .frame(maxHeight: .infinity)
    }
}
