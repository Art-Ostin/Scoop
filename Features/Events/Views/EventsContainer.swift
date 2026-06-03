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

    var body: some View {
            Group {
                if vm.events.isEmpty {
                        AppScrollView(title: "Events") {
                            EventsPlaceholder()
                        }
                } else {
                    ZStack {
                        AppScrollView(title: "Events") {
                            eventsScrollView
                        }

                        if let profile = ui.selectedProfile {
                            profileView(profile: profile)
                        }
                    }
                    .overlay(alignment: .top) {AnimatedPageIndicator(count: vm.events.count, progress: scrollProgress)}
                }
            }
            .navigationDestination(for: EventProfile.self) { eventProfile in
                chatView(eventProfile: eventProfile)
                    .navigationTransition(.zoom(sourceID: eventProfile.id, in: zoomNS))
            }
            .sheet(item: $ui.showCantMakeIt) {CantMakeIt(vm: vm, eventProfile: $0)}
            .getImageSize(imageSize: $ui.imageSize, horizontalPadding: 16)
            .onPreferenceChange(ScrollNavBarVisibleKey.self) { ui.isScrollNavBarVisible = $0 }
            .background(Color.appCanvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        .hideTabBar(hideBar: !path.isEmpty)
        .onChange(of: showMessageScreen) { _, newValue in
            handleDeepLink(eventId: newValue)
        }
    }

    private func handleDeepLink(eventId: String?) {
        guard let eventId, let eventProfile = vm.event(id: eventId) else { return }
        if path.isEmpty { path.append(eventProfile) }
        showMessageScreen = nil
    }
}

//The Event Slots screens
extension EventsContainer {

    private func eventSlot(_ eventProfile: EventProfile) -> some View {
            EventSlotContainer(ui: ui, eventProfile: eventProfile, imageSize: ui.imageSize, zoomNS: zoomNS) { openMaps(eventProfile)}
                .task{await loadProfileImages(eventProfile.profile)}
                .tag(eventProfile)
    }
    
    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}

//The tab indicator
extension EventsContainer {
    
    private var eventsScrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(vm.events) { eventProfile in
                    eventSlot(eventProfile)
                        .id(eventProfile.id)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $ui.selectedEventId)
        .scrollIndicators(.hidden)
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
    }
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(profile: profile, event: vm.event(forProfile: profile.id)?.event, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: ui.profileImages[profile.id] ?? [],
            mode: .viewProfile,
            onDismiss: { ui.selectedProfile = nil })
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }

    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        ui.profileImages[profile.id] = loadedImages
    }
}
