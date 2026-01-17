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
        .fullScreenCover(isPresented: $showProfileView) {NavigationStack {editProfileScreen()}}
        .overlay(alignment: .topTrailing) {profileButton}
        .task { await prepareUserImages() }
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
                        .padding(.horizontal)
                } else {
                    Image("ProfileImagePlaceholder")
                }
            }
        }
    }
}
//Additional Functions
extension MatchesView {
    private func editProfileScreen() -> some View {
        EditProfileContainer(
            vm: EditProfileViewModel(
                cacheManager: vm.cacheManager,
                s: vm.s,
                userManager: vm.userManager,
                storageManager: vm.storageManager
            ),
            profileVM: ProfileViewModel(
                profileModel: ProfileModel(profile: vm.user),
                cacheManager: vm.cacheManager
            ),
            selectedProfile: nil, images: $userProfileImages
        )
    }
    
    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authManager: vm.authManager, sessionManager: vm.s))
    }
    
    private func prepareUserImages() async {
        let loadedUserImages = await vm.loadUserImages()
        await MainActor.run {userProfileImages = loadedUserImages}
    }
}



//Old Way of fetching only first image:
/*
 .task(id: vm.user) {image = try? await vm.fetchFirstImage()}
 @State var image: UIImage?

 */


/*
 
 ZStack {
     Color.background
     ScrollView {
         VStack(spacing: 36) {
             VStack(spacing: 14) {
                 tabSection
                 TabTitle(page: .Matches, offset: $scrollViewOffset)
             }
         }
     }
     .onPreferenceChange(TitleOffsetsKey.self) {value in
         scrollViewOffset = value[.Matches] ?? 0
     }
     .coordinateSpace(name: Page.Matches)
 }
 @State var scrollViewOffset: CGFloat = 0
 */
