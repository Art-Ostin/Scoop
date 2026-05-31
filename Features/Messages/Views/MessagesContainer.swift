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

struct MessagesContainer: View {

    @State private var vm: MessagesViewModel
    @State private var userProfileImages: [UIImage] = []

    @Namespace private var settingsZoomNS
    @Namespace private var profileZoomNS

    @Binding var path: NavigationPath
    
    
    init(vm: MessagesViewModel, path: Binding<NavigationPath>) {
        _vm = State(initialValue: vm)
        _path = path
    }

    var body: some View {
        AppScrollView(title: "Message") {
            ZStack {
                if vm.events.isEmpty {
                    messagesAppearHereView
                } else {
                    matchesView
                        .padding(.top, -12)
                }
            }
        }
        .overlay(alignment: .topTrailing) { actionBar }
        .task(id: vm.user.imagePathURL) { await prepareUserImages() }
        .navigationDestination(for: PastEventsRoute.self, destination: destination)
        .overlay {
            if #available(iOS 26.0, *) {
                Button {
                    // action
                } label: {
                    Image(systemName: "message.fill")
                        .font(.body.weight(.bold))
                        .padding(10)
                }
                .buttonStyle(.glassProminent)
            } else {
                // Fallback on earlier versions
            }
        }
        .overlay(alignment: .bottom) {
            if #available(iOS 26.0, *) {
                Button {
                    // action
                } label: {
                    Image(systemName: "message.fill")
                        .font(.body.weight(.bold))
                        .padding(10)
                    
                }
                .buttonStyle(.glass)
                .padding(.bottom, 144)
            } else {
                // Fallback on earlier versions
            }
        }
        .overlay(alignment: .bottom) {
                Button {
                    // action
                } label: {
                    Image(systemName: "message.fill")
                        .font(.body.weight(.bold))
                        .padding(10)
                    
                }
                .buttonStyle(.borderless)
                .padding(.bottom, 50)
        }
    }
}

extension MessagesContainer {
    
    // MARK: - Subviews
    private var matchesView: some View {
        VStack(spacing: 0) {
            ForEach(vm.events) { eventProfile in
                NavigationLink(value: PastEventsRoute.chat(eventProfile)) {
                    let chatPreview = ChatPreviewModel(eventProfile: eventProfile)
                    ChatRowView(chatPreview: chatPreview)
                        .id(chatPreview)
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

    private var actionBar: some View {
        HStack {
            SettingsButton(zoomNS: settingsZoomNS, action: { path.append(PastEventsRoute.settings) })
            Spacer()
            profileButton
        }
        .padding(.horizontal, 16)
    }
    
    private var profileButton: some View {
        Button {
            path.append(PastEventsRoute.editProfile)
        } label: {
            Group { 
                if let img = userProfileImages.first, img.size != .zero {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 35, height: 35)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 7, x: 0, y: 10)
            .matchedTransitionSource(id: "editProfile", in: profileZoomNS)
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(for route: PastEventsRoute) -> some View {
        switch route {
        case .chat(let eventProfile):
            chatScreen(for: eventProfile)
        case .settings:
            settingScreen()
                .navigationTransition(.zoom(sourceID: "settings", in: settingsZoomNS))
        case .editProfile:
            userProfileScreen()
                .navigationTransition(.zoom(sourceID: "editProfile", in: profileZoomNS))
        }
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

    private func settingScreen() -> some View {
        SettingsView(vm: SettingsViewModel(authService: vm.authService, session: vm.s, defaults: vm.defaults))
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
    }

    // MARK: - Actions

    private func prepareUserImages() async {
        userProfileImages = await vm.loadUserImages()
    }

    private func updateMessagesToRead(_ eventProfile: EventProfile) async throws {
        guard let count = eventProfile.event.chatState?.unreadCount, count > 0 else { return }
        try await vm.readMessages(userEventId: eventProfile.event.id, userId: vm.user.id)
    }
}
