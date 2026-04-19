//
//  MatchesView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI
import FirebaseFunctions


struct MessagesContainer: View {
    
    @Environment(\.appState) private var appState
    @State var vm: MessagesViewModel
    @State var showProfileView = false
    @State var showSettingsView = false
    @State var userProfileImages: [UIImage] = []
    @State var firstProfileImages: [String : UIImage] = [:]
    
    @State var selectedProfile: EventProfile? = nil
    
    init(vm: MessagesViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            CustomTabPage(page: .pastMatches, tabAction: $showSettingsView) {
                if vm.events.isEmpty {
                    messagesAppearHereView
                } else {
                    matchesView
                        .padding(.top, -12)
                }
            }
            .fullScreenCover(isPresented: $showSettingsView) {NavigationStack {settingScreen()}}
            .fullScreenCover(isPresented: $showProfileView) { editProfileScreen() }
            .overlay(alignment: .topTrailing) {actionBar}
            .task(id: vm.user.imagePathURL) { await prepareUserImages() }
        }
    }
}

//Additonal Views
extension MessagesContainer {
    
    @ViewBuilder
    private var matchesView: some View {
            VStack(spacing: 0) {
//                MapDivider()
//                    .padding(.trailing, -20)
//                    .padding(.leading, 16)
                ForEach(vm.events) { eventProfile in
                    NavigationLink {
                        ChatContainer(vm: ChatViewModel(defaults: vm.defaults, session: vm.s, chatRepo: vm.chatRepo, imageLoader: vm.imageLoader, eventProfile: eventProfile, messages: <#[MessageModel]#>), isEvent: false)
                    } label: {
                        ChatRowView(image: firstProfileImages[eventProfile.id] ?? UIImage(), event: eventProfile.event)
                            .task {
                                firstProfileImages[eventProfile.id] = try? await vm.fetchFirstProfileImage(profile: eventProfile.profile)
                            }
                    }
                }
            }
    }
    
    private var messagesAppearHereView: some View {
        VStack(spacing: 96) {
            Text("Message your past matches here")
                .font(.title(20, .medium))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Image("CoolGuys")
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(width: 250, height: 250)
        }
        .padding(.top, 72)
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
    
    private var actionBar: some View {
        HStack {
            SettingsButton(showSettingsView: $showSettingsView)
            Spacer()
            profileButton
        }
        .padding(.horizontal, 16)
    }
}
//Additional Functions
extension MessagesContainer {
    private func editProfileScreen() -> some View {
        EditProfileContainer(
            vm: EditProfileViewModel(
                s: vm.s, storageService: vm.storageService,
                userRepo: vm.userRepo,
                imageLoader: vm.imageLoader,
                importedImages: userProfileImages
            ),
            profileVM: ProfileViewModel(
                defaults: vm.defaults,
                s: vm.s, profile: vm.user,
                imageLoader: vm.imageLoader
            ),
            selectedProfile: nil)
    }
    
    
    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authService: vm.authService, sessionManager: vm.s))
    }
    
    private func prepareUserImages() async {
        let loadedUserImages = await vm.loadUserImages()
        userProfileImages = loadedUserImages
    }
}
