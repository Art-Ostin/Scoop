//
//  MessagesContainer.swift
//  Scoop
//

import SwiftUI

enum PastEventsRoute: Hashable {
    case chat(EventProfile)
}

//1. Need to user overlay, not toolbar, for messages, as toolbar does not allow zoomTransition
struct MessagesContainer: View {
    
    //Injected (path owned by the parent so it can jump tabs)
    let vm: MessagesViewModel
    @Binding var path: NavigationPath
    
    //Local view state
    @State private var userProfileImages: [UIImage] = []
    @State private var userProfileGallery: [String] = [] //The stored imagePathURL those photos were loaded from
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var editProfileVM: EditProfileViewModel? //Built on each open; outlives the cover so a swipe away can still save
    @State private var showSaveAlert = false
    @Namespace private var settingsZoom
    @Namespace private var profileZoom
    
    var body: some View {
        ZoomNavigationStack {
            NavigationStack(path: $path) {
                TabScrollView(type: .messages, showEmptyView: vm.events.isEmpty) {
                    VStack(spacing: 0) {
                        ForEach(vm.events) { chatRow(for: $0) }
                    }
                    .padding(.top, -24)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        settingsButton
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        profileImage
                    }
                }
                
                .navigationDestination(for: PastEventsRoute.self, destination: destination)
                .fullScreenCover(isPresented: $showSettings) {settingScreen()}
                .fullScreenCover(isPresented: $showProfile, onDismiss: offerToSave) { [editProfileVM] in //Captured so the body tracks it, or the cover opens on a stale nil
                    userProfileScreen(editProfileVM)
                }
            }
        }
        .ignoresSafeArea()
        .task(id: vm.user.imagePathURL) { await prepareUserImages() } //Re-seeds after a save, so Edit Profile reopens on the stored order
        .hideTabBar(!path.isEmpty)
        .customAlertCard(
            isPresented: $showSaveAlert,
            title: "Unsaved Changes",
            message: "Would you like to save your changes",
            cancelTitle: "No",
            okTitle: "Yes",
            onOK: saveEdits,
            onCancel: { showSaveAlert = false; editProfileVM?.discardEdits() } //The card's buttons don't close it themselves; No drops the edits and whatever they uploaded
        )
    }
}

//1. Two Main views
extension MessagesContainer {
    
    private func chatRow(for eventProfile: EventProfile) -> some View {
        NavigationLink(value: PastEventsRoute.chat(eventProfile)) {
            let chatPreview = ChatPreview(eventProfile: eventProfile)
            ChatRowView(chatPreview: chatPreview)
                .id(eventProfile.id)
        }
    }

    private var messagesPlaceholder: some View {
        VStack(spacing: Spacing.titleGap) {
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
        .padding(.top, Spacing.titleGap)
    }
}
    
//2. Components used in Container
extension MessagesContainer {
    
    @ViewBuilder
    private var profileImage: some View {
        if let img = userProfileImages.first {
            SmallImage(image: img, size: 32, isCircle: true)
                .matchedTransitionSource(id: "profile", in: profileZoom)
                .shrinkPress {
                    editProfileVM = makeEditProfileVM()
                    showProfile = true
                }
        }
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        Image("SettingsEmpty")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.black)
            .frame(width: 22, height: 22)
            .background(Color.clear)
            .shrinkPress {
                showSettings = true
            }
            .matchedTransitionSource(id: "settings", in: settingsZoom)
    }
}
    
//2. screens to go to, and navigation wiring where to go
extension MessagesContainer {
    
    @ViewBuilder
    private func destination(for route: PastEventsRoute) -> some View {
        switch route {
        case .chat(let eventProfile):
            chatScreen(for: eventProfile)
        }
    }
    
    @ViewBuilder
    private func userProfileScreen(_ editVM: EditProfileViewModel?) -> some View {
        if let editVM {
            EditProfileContainer(
                vm: editVM,
                profileVM: ProfileViewModel(
                    profile: vm.user,
                    imageLoader: vm.imageLoader,
                    defaults: vm.defaults
                )
            )
            .navigationTransition(.zoom(sourceID: "profile", in: profileZoom))
        }
    }

    private func makeEditProfileVM() -> EditProfileViewModel {
        EditProfileViewModel(
            session: vm.session,
            storageService: vm.storageService,
            userRepo: vm.userRepo,
            imageLoader: vm.imageLoader,
            importedImages: userProfileImages,
            importedGallery: userProfileGallery
        )
    }
    
    private func settingScreen() -> some View {
        SettingsContainer(vm: SettingsViewModel(authService: vm.authService, session: vm.session, defaults: vm.defaults))
            .navigationTransition(.zoom(sourceID: "settings", in: settingsZoom))
    }
    
    private func chatScreen(for eventProfile: EventProfile) -> some View {
        ChatContainer(
            defaults: vm.defaults,
            session: vm.session,
            chatRepo: vm.chatRepo,
            imageLoader: vm.imageLoader,
            eventProfile: eventProfile,
            isEvent: false,
        )
        .task { try? await updateMessagesToRead(eventProfile) }
    }
}

//3. components only used in this screen
extension MessagesContainer {
    
    //Any close, swipe or X, that leaves edits no save has landed offers them a save here
    private func offerToSave() {
        if editProfileVM?.hasUnsavedChanges == true { showSaveAlert = true }
    }

    //The cover is already gone, so the write runs behind the Messages screen; a failure drops the edits and their uploads
    private func saveEdits() {
        showSaveAlert = false
        guard let editProfileVM else { return }
        Task {
            do { try await editProfileVM.saveProfileChanges() }
            catch {
                vm.session.notifications.push(.error(message: "Your profile changes couldn't be saved."))
                editProfileVM.discardEdits()
            }
        }
    }

    private func prepareUserImages() async {
        let gallery = vm.user.imagePathURL //Taken with the load, so the photos always carry the gallery they show
        let images = await vm.loadUserImages()
        guard !Task.isCancelled else { return } //A newer gallery's load owns the seed
        userProfileImages = images
        userProfileGallery = gallery
    }
    
    private func updateMessagesToRead(_ eventProfile: EventProfile) async throws {
        guard let count = eventProfile.event.chatState?.unreadCount, count > 0 else { return }
        try await vm.readMessages(userEventId: eventProfile.event.id, userId: vm.user.id)
    }
}


/*
 @ToolbarContentBuilder
 private var profileButton: some ToolbarContent {
     ToolbarItem(placement: .topBarTrailing) {
         if let img = userProfileImages.first {
             ScoopButton(shape: Circle()) {
                 showProfile = true
             } label: {
                 Image(uiImage: img)
                     .resizable()
                     .scaledToFill()
                     .frame(width: 35, height: 35, alignment: .trailing)
                     .clipShape(Circle())
                     .padding(10)
             }
             .matchedTransitionSource(id: "profile", in: profileZoom)
         } else {
             Circle()
                 .fill(Color.fillGray)
                 .frame(width: 35, height: 35)
         }
     }
     .hideToolbarBackground()
 }
 
 @ToolbarContentBuilder
 private var settingsButton: some ToolbarContent {
     ToolbarItem(placement: .topBarLeading) {
         SettingsButton { showSettings = true }
             .matchedTransitionSource(id: "settings", in: settingsZoom) { source in
                 source
                     .clipShape(.rect(cornerRadius: 27, style: .circular)) //Circle in disguise: matchedTransitionSource only accepts RoundedRectangle
                     .background(Color.appCanvas)
             }
             .padding(.leading, -10) //So it anchors to the left
     }
     .hideToolbarBackground()
 }


 */
