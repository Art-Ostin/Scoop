//
//  EventView.swift
//  Scoop
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventsContainer: View {

    //Injected
    @State var vm: EventsViewModel
    @Binding var showMessageScreen: String?
    @Binding var path: NavigationPath

    //Local View state
    @State private var ui = EventsUIState()
    @State private var morph = ProfileMorphState()
    @State private var userImage: UIImage? = nil
    @Namespace var zoomNS

    private var currentProfile: EventProfile? {
        vm.event(id: ui.selectedEventId) ?? vm.events.first
    }
    
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
        .hideTabBar(hideBar: !path.isEmpty) //Chat: path-based, so it reappears the moment you pop (no flicker)
        .onChange(of: showMessageScreen) { _, newValue in
            handleDeepLink(eventId: newValue)
        }
        .task {userImage = try? await vm.fetchUserImage() }
    }
}

//The Event Slots screens
extension EventsContainer {

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
        .pagedScroll()
        .scrollPosition(id: $ui.selectedEventId)
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
        ProfileContainer(
            vm:ProfileViewModel(profile: profile, event: vm.event(forProfile: profile.id)?.event, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: ui.profileImages[profile.id] ?? seedImages(for: profile),
            mode: .viewProfile,
            onDismiss: { ui.selectedProfile = nil })
        .id(profile.id)
        .opacity(morph.contentOpacity)
        .environment(morph)
    }

    //If the async profile images haven't landed yet, seed the pager with the tapped
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.event(forProfile: profile.id)?.image.map { [$0] } ?? []
    }
}


//Functions and Components
extension EventsContainer {

    //1. Load Images
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadProfileImages(profile: profile)
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
