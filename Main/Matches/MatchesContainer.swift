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
    @State var showSettingsView = false
    @State var userProfileImages: [UIImage] = []
    
    init(vm: MatchesViewModel) { _vm = State(initialValue: vm)}
    
    var body: some View {
        CustomTabPage(page: .Matches, TabAction: $showSettingsView) {
            Text("Hello World")
        }
        .fullScreenCover(isPresented: $showSettingsView) {NavigationStack {settingScreen()}}
        .fullScreenCover(isPresented: $showProfileView) { editProfileScreen() }
        .overlay(alignment: .topTrailing) {actionBar}
        .task(id: vm.user.imagePathURL) { await prepareUserImages() }
    }
}

//Additonal Views
extension MatchesView {
    
    private var tabSection: some View {
        HStack(alignment: .top) {
            TabButton(page: .Matches, isPresented: $showSettingsView)
            Spacer()
        }
        .padding(.top, 48)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    private var noMatchesView: some View {
        VStack(spacing: 32) {
            Image("DancingCats")
            
            Text("View your past Meet Ups Here")
                .font(.body(20))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var profileButton: some View {
        Button {
            showProfileView = true
        } label: {
            Group {
                if let img = userProfileImages.first, img.size != .zero {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 7, x: 0, y: 10)
                } else {
                    Image("ProfileImagePlaceholder")
                        .padding(.top, 10)
                        .shadow(color: .black.opacity(0.15), radius: 7, x: 0, y: 10)
                }
            }
        }
    }
    private var settingsButton: some View {
        Button {
            showSettingsView.toggle()
        } label: {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 35, height: 35)
                .glassIfAvailable(Circle())
                .contentShape(Circle())
        }
    }
    private var actionBar: some View {
        HStack {
            settingsButton
            Spacer()
            profileButton
        }
        .padding(.horizontal, 16)
    }
}
//Additional Functions
extension MatchesView {
    private func editProfileScreen() -> some View {
        EditProfileContainer(
            vm: EditProfileViewModel(cacheManager: vm.cacheManager, s: vm.s, userManager: vm.userManager, storageManager: vm.storageManager, importedImages: userProfileImages),
            profileVM: ProfileViewModel(profileModel: ProfileModel(profile: vm.user), cacheManager: vm.cacheManager),
            selectedProfile: nil)
    }
    
    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))
    }
    
    private func prepareUserImages() async {
        let loadedUserImages = await vm.loadUserImages()
        await MainActor.run {userProfileImages = loadedUserImages}
    }
}
