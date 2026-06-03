//
//  MessagesContainer.swift
//  Scoop
//

import SwiftUI

enum PastEventsRoute: Hashable {
    case chat(EventProfile)
    case settings
    case editProfile
}

//1. Need to user overlay, not toolbar, for messages, as toolbar does not allow zoomTransition
struct MessagesContainer: View {
    
    @State private var vm: MessagesViewModel
    @State private var userProfileImages: [UIImage] = []
    
    @State private var showSheet = false
    
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
            .toolbar { messagesToolbar }
            .navigationDestination(for: PastEventsRoute.self, destination: destination)
        }
        .task { await prepareUserImages() }
        .hideTabBar(hideBar: !path.isEmpty)
        .fullScreenCover(isPresented: $showSheet) {
            settingScreen()
        }
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
    //2. The different components of the view
    @ToolbarContentBuilder
    private var messagesToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { settingsButton }.hideToolbarBackground()
        ToolbarItem(placement: .topBarTrailing) { profileButton }.hideToolbarBackground()
    }
    
    //A. The Button and the Icon for profile
    private var profileButton: some View {
        ScoopButton(shape: Circle(), size: .medium) {
            path.append(PastEventsRoute.editProfile)
        } label: {
            profileIcon
        }
        .offset(x: 10)//As Tabbackground hidden, this pins it to outer edge
    }
    
    @ViewBuilder
    private var profileIcon: some View {
        if let img = userProfileImages.first, img.size != .zero {
            Image(uiImage: img)               // was `image` — use `img`
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .buttonShadow(.high)
        } else {
            Circle()
                .fill(Color.gray.opacity(0.2))
        }
    }
    
    
    private var settingsButton: some View {
        SettingsButton {
            showSheet = true
        }
        .offset(x: -10)//As TabButton background hidden, this pins it to outer edge
    }
}

    
//2. screens to go to, and navigation wiring where to go
extension MessagesContainer {
    
    @ViewBuilder
    private func destination(for route: PastEventsRoute) -> some View {
        switch route {
        case .chat(let eventProfile):
            chatScreen(for: eventProfile)
        case .settings:
            settingScreen()
        case .editProfile:
            userProfileScreen()
        }
    }
    
    private func userProfileScreen() -> some View {
        NavigationStack {
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
        }
    }
    
    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authService: vm.authService, session: vm.s, defaults: vm.defaults))
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
