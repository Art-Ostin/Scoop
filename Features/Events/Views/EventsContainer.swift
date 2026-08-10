//
//  EventView.swift
//  Scoop
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventsContainer: View {

    //Injected
    let vm: EventsViewModel
    @Binding var showMessageScreen: String?
    @Binding var path: NavigationPath

    //Local View state
    @State private var ui = EventsUIState()
    @State private var userImage: UIImage? = nil
    @Namespace var zoomNS

    private var currentProfile: EventProfile? {
        vm.event(id: ui.selectedEventId) ?? vm.events.first
    }
    
    private var eventsTitle: String {
        vm.events.isEmpty ? "Events" : "\(currentProfile?.profile.name ?? "")"
    }
    
    var body: some View {
        ZoomNavigationStack {
            NavigationStack(path: $path) {
                TabScrollView(type: .events, showEmptyView: vm.events.isEmpty, name: eventsTitle) {
                    eventsList
                }
                .overlay(alignment: .bottomTrailing) { messageButton }
                .navigationDestination(for: EventProfile.self) { chatView(eventProfile: $0) }
            }
        }
        .ignoresSafeArea()
        .hideTabBar(!path.isEmpty)
        .onChange(of: showMessageScreen) {handleDeepLink(eventId: $1)}
        .task {userImage = try? await vm.fetchUserImage() }
        .sheet(item: $ui.showCantMakeIt) {CantMakeIt(vm: vm, eventProfile: $0)}
    }
}

//The Event Slots screens
extension EventsContainer {

    private var eventsList: some View {
        EventsPager(selectedEventId: $ui.selectedEventId) {
            ForEach(vm.events) { eventProfile in
                eventSlot(eventProfile)
            }
        }
    }
    
    
    //userImage is optional all the way down: it lands asynchronously and must never gate the page.
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        EventSlot(
            ui: ui,
            eventProfile: eventProfile,
            userImage: userImage,
            imageLoader: vm.imageLoader,
            defaults: vm.defaults) {
                openMaps(eventProfile)
            }
        .padding(.horizontal, Spacing.gutter)
        .containerRelativeFrame(.horizontal)
        .id(eventProfile.id)
        .task {await loadProfileImages(eventProfile.profile)}
    }
    
    @ViewBuilder
    private var messageButton: some View {
        if let eventProfile = currentProfile {
            ScoopButton(shape: Circle()) {
                path.append(eventProfile)
            } label: {
                Image("NewMessageIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(Spacing.sm)
            }
            .matchedTransitionSource(id: eventProfile.id, in: zoomNS)
            .padding(.bottom, Spacing.xxl)
            .padding(.horizontal, Spacing.margin)
        }
    }
}

///The pager keeps its own page id. Routing every landing straight into `ui` would invalidate
///EventsContainer — the title and the message button read `selectedEventId` — while the paging
///animation is still running, and the re-applied `scrollPosition` then snaps the offset to the
///target instead of letting it settle. Only the resting page travels back up.
private struct EventsPager<Content: View>: View {

    //Injected
    @Binding var selectedEventId: String?
    @ViewBuilder let content: Content

    //Local view state
    @State private var pagedId: String?

    var body: some View {
        HorizontalScrollView(progress: .constant(0)) {
            content
        }
        .scrollPosition(id: $pagedId)
        .onScrollPhaseChange { _, phase in
            guard phase == .idle, pagedId != selectedEventId else { return }
            selectedEventId = pagedId
        }
        .onChange(of: selectedEventId) { _, newId in
            guard let newId, newId != pagedId else { return } //Deep links jump the pager
            pagedId = newId
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
