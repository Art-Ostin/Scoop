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
    
    @State private var vm: MessagesViewModel
    @State private var userProfileImages: [UIImage] = []
    
    @State private var showSettings = false
    @Namespace private var settingsZoom


    @State private var showProfile = false
    @Namespace private var profileZoom

    //Path owned by parent to jump
    @Binding var path: NavigationPath
    
    init(vm: MessagesViewModel, path: Binding<NavigationPath>) {
        _vm = State(initialValue: vm)
        _path = path
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            AppScrollView(title: "Messages") {
                if vm.events.isEmpty {          
                    messagesPlaceholder
                } else {
                    VStack(spacing: 0) {
                        ForEach(vm.events) { chatRow(for: $0) }
                    }
                }
            }
            .toolbar {settingsButton ; profileButton}
            .navigationDestination(for: PastEventsRoute.self, destination: destination)
            .fullScreenCover(isPresented: $showSettings) {
                settingScreen()
            }
            .fullScreenCover(isPresented: $showProfile) {
                userProfileScreen()
            }
        }
        .task { await prepareUserImages() }
        .hideTabBar(hideBar: !path.isEmpty)
    }
}

//1. Two Main views
extension MessagesContainer {
    
    private func chatRow(for eventProfile: EventProfile) -> some View {
        NavigationLink(value: PastEventsRoute.chat(eventProfile)) {
            let chatPreview = ChatPreviewModel(eventProfile: eventProfile)
            ChatRowView(chatPreview: chatPreview)
                .id(eventProfile.id)
        }
    }

    private var messagesPlaceholder: some View {
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
}
    
//2. Components used in Container
extension MessagesContainer {
    
    @ToolbarContentBuilder
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SettingsButton { showSettings = true }
                .matchedTransitionSource(id: "settings", in: settingsZoom) { source in
                    source
                        .clipShape(.rect(cornerRadius: 27)) // small performance improvement
                        .background(Color.appCanvas)
                }
                .padding(.leading, -10) //So it anchors to the left
        }
        .hideToolbarBackground()
    }
    
    @ToolbarContentBuilder
    private var profileButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if let img = userProfileImages.first, img.size != .zero {
                ScoopButton(shape: Circle()) {
                    showProfile = true
                } label: {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35, alignment: .trailing)
                        .clipShape(Circle())
                }
                .matchedTransitionSource(id: "profile", in: profileZoom)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 35, height: 35)
            }
        }
        .hideToolbarBackground()
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
    
    private func userProfileScreen() -> some View {
        EditProfileContainer(
            vm: EditProfileViewModel(
                s: vm.s,
                storageService: vm.storageService,
                userRepo: vm.userRepo,
                imageLoader: vm.imageLoader,
                importedImages: userProfileImages
            ),
            profileVM: ProfileViewModel(
                profile: vm.user,
                imageLoader: vm.imageLoader,
                defaults: vm.defaults
            )
        )
        .navigationTransition(.zoom(sourceID: "profile", in: profileZoom))
    }
    
    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authService: vm.authService, session: vm.s, defaults: vm.defaults))
            .navigationTransition(.zoom(sourceID: "settings", in: settingsZoom))
    }
    
    private func chatScreen(for eventProfile: EventProfile) -> some View {
        ChatContainer(
            defaults: vm.defaults,
            session: vm.s,
            chatRepo: vm.chatRepo,
            imageLoader: vm.imageLoader,
            eventProfile: eventProfile,
            isEvent: false
        )
        .task { try? await updateMessagesToRead(eventProfile) }
    }
}

//3. components only used in this screen
extension MessagesContainer {
    
    private func prepareUserImages() async {
        userProfileImages = await vm.loadUserImages()
    }
    
    private func updateMessagesToRead(_ eventProfile: EventProfile) async throws {
        guard let count = eventProfile.event.chatState?.unreadCount, count > 0 else { return }
        try await vm.readMessages(userEventId: eventProfile.event.id, userId: vm.user.id)
    }
}
