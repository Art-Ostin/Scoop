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

    @State var userImage: UIImage? = nil
    @State private var morph = ProfileMorphState()

    var body: some View {
        NavigationStack(path: $path) {
            eventsRootView
                .navigationDestination(for: EventProfile.self) {chatView(eventProfile: $0)}
        }
        .profileMorphHost(morph)
        .profileView(presentedID: ui.selectedProfile?.id) {
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

    //Same shell as the other containers: one stable AppScrollView owns the
    //vertical scroll and the native title (Scoop font via scoopNavigationBarFonts),
    //and the empty/loaded branch swaps inside it — swapping the whole scroll view
    //out from under the stack makes the system reconfigure the bar from scratch.
    //The pager inside it only swipes the event slots horizontally.
    private var eventsRootView: some View {
        AppScrollView(title: vm.events.isEmpty ? "Events" : "Meeting \(currentProfile?.profile.name ?? "")") {
            if vm.events.isEmpty {
                EventsPlaceholder()
            } else {
                eventsPager
            }
        }
        .overlay(alignment: .bottomTrailing) { messageButton }
    }

    private var eventsPager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(vm.events) { eventProfile in
                    eventSlot(eventProfile)
                        .padding(.horizontal, 16)
                        .padding(.top, 32)
                        .padding(.bottom, 84)
                        .containerRelativeFrame(.horizontal)
                        .id(eventProfile.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $ui.selectedEventId)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        if let userImage {
            EventSlot(ui: ui, eventProfile: eventProfile, imageSize: ui.imageSize, userImage: userImage) {
                openMaps(eventProfile)
            }
            .task {await loadProfileImages(eventProfile.profile)}
        }
    }

    //Floats above the current event page and zooms into its chat
    @ViewBuilder
    private var messageButton: some View {
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
        .opacity(morph.contentOpacity)
        .environment(morph)
    }

    //If the async profile images haven't landed yet, seed the pager with the tapped
    //card image so the morph destination exists (and is identical) on frame one.
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.event(forProfile: profile.id)?.image.map { [$0] } ?? []
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
        ui.selectedEventId = eventProfile.id //Jump the pager to that event's page first
        if path.isEmpty { path.append(eventProfile) }
        showMessageScreen = nil
    }

    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}
