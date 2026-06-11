//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.


import SwiftUI

struct EventsContainer: View {

    @State var vm: EventViewModel
    @State private var ui = EventUIState()

    @Binding var showMessageScreen: String?

    private var currentProfile: EventProfile? {
        vm.event(id: ui.selectedEventId) ?? vm.events.first
    }
    
    @Namespace var zoomNS
    @Binding var path: NavigationPath
    
    @State private var scrollProgress: Double = 0
    @State private var showInlineTitle = false
    
    @State var userImage: UIImage? = nil
    @State private var morph = ProfileMorphState()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                eventsRootView
                    .navigationDestination(for: EventProfile.self) {chatView(eventProfile: $0)}
                    .toolbar {tabTest}
                
            }
        }
        //The floating copy of the tapped card image, flying between card and pager.
        .profileMorphHost(morph)
        //Presents above the root TabView, so the real tab bar sits behind the
        //profile — covered while open, revealed + dimmed during the zoom dismissal.
        .profileOverlay(id: ui.selectedProfile?.id) {
            if let profile = ui.selectedProfile { profileView(profile: profile) }
        }
        .sheet(item: $ui.showCantMakeIt) {CantMakeIt(vm: vm, eventProfile: $0)}
        .getImageSize(imageSize: $ui.imageSize, horizontalPadding: 22) //16 padding, /6 inside padding on card
        .hideTabBar(hideBar: !path.isEmpty) //Chat: path-based, so it reappears the moment you pop (no flicker)
        .onChange(of: showMessageScreen) { _, newValue in
            handleDeepLink(eventId: newValue)
        }
        .task {userImage = try? await vm.fetchUserImage() }
        
    }
}

//The Event Slots screens
extension EventsContainer {
    
    @ViewBuilder
    private var eventsRootView: some View {
            if vm.events.isEmpty {
                EventsPlaceholder()
            } else {
                eventsScrollView
            }
        }
    
    private var eventsScrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(vm.events) { eventProfile in
                    eventPage(eventProfile)
                        .containerRelativeFrame(.horizontal)
                        .id(eventProfile.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $ui.selectedEventId)
        .scrollIndicators(.hidden)
        .colorBackground()
        .overlay(alignment: .bottomTrailing) { messageOverlay }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(showInlineTitle ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Events")
                    .font(.title(17, .semibold))
                    .opacity(showInlineTitle ? 1 : 0)
            }
        }
        .onChange(of: ui.selectedEventId) { showInlineTitle = false }
    }

    private func eventPage(_ eventProfile: EventProfile) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Events")
                    .font(.title(32, .bold))
                    .opacity(showInlineTitle ? 0 : 1)
                eventSlot(eventProfile)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 84)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top
        } action: { _, distanceFromTop in
            guard (ui.selectedEventId ?? vm.events.first?.id) == eventProfile.id else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showInlineTitle = distanceFromTop > 40
            }
        }
    }

    @ViewBuilder
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        if let userImage {
            EventSlot(ui: ui, eventProfile: eventProfile, imageSize: ui.imageSize, userImage: userImage) {
                openMaps(eventProfile)
            }
                    .task{await loadProfileImages(eventProfile.profile)}
        }
    }

    //Floats above the current event page and zooms into its chat
    @ViewBuilder
    private var messageOverlay: some View {
        if let eventProfile = currentProfile {
            NavigationLink(value: eventProfile) {
                Image("NewMessageIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(10)
                    .glassBackgroundIfAvailable(shape: Circle())
                    .expandHitArea(24)
            }
            .matchedTransitionSource(id: eventProfile.id, in: zoomNS)
            .padding(.bottom, 96)
            .padding(.horizontal, 24)
        }
    }
}

//The different Views
extension EventsContainer {
    
    private func chatView(eventProfile: EventProfile) -> some View {
        ChatContainer(
            defaults: vm.defaults,
            session: vm.session,
            chatRepo: vm.chatRepo,
            imageLoader: vm.imageLoader,
            eventProfile: eventProfile,
            isEvent: true
        )
        .navigationTransition(.zoom(sourceID: eventProfile.id, in: zoomNS))
    }
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(profile: profile, event: vm.event(forProfile: profile.id)?.event, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: ui.profileImages[profile.id] ?? seedImages(for: profile),
            mode: .viewProfile,
            onDismiss: { ui.selectedProfile = nil })
        .id(profile.id)
        //Cross-fades in the same 0.3s transaction as the image flight (no slide —
        //the morphing image is the hero, everything else fades around it).
        .opacity(morph.contentOpacity)
        //Rendered at the app root, outside this container's environment.
        .environment(morph)
    }

    //If the async profile images haven't landed yet, seed the pager with the tapped
    //card image so the morph destination exists (and is identical) on frame one.
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.event(forProfile: profile.id)?.image.map { [$0] } ?? []
    }
    
    private var tabTest: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ScoopButton(style: .clearGlass, shape: .rect(cornerRadius: 16)) {
            } label: {
                Text("Arthur · 23 May")
                    .font(.body(15, .bold))
                    .frame(height: 35)
                    .padding(.horizontal, 10)
                    .stroke(16, lineWidth: 1, color: Color(red: 0.55, green: 0, blue: 0.25))
            }
        }
        .hideToolbarBackground()
    }
}


//Functions and Components
extension EventsContainer {
    
    //1. Load Images
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        ui.profileImages[profile.id] = loadedImages
    }
    
    private func handleDeepLink(eventId: String?) {
        guard let eventId, let eventProfile = vm.event(id: eventId) else { return }
        if path.isEmpty { path.append(eventProfile) }
        showMessageScreen = nil
    }
    
    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}


