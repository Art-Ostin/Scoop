//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventsContainer: View {
    
    @State var vm: EventViewModel
    @State private var ui = EventUIState()
    
    @State private var tabProfile: EventProfile?
    @State private var profileImages: [String: [UIImage]] = [:]
    
    @State private var imageSize: CGFloat = 0
    
    var body: some View {
        
        if vm.events.isEmpty  {
            EventsPlaceholder()
        } else {
            ZStack {
                eventPages
                
                if let profile = ui.selectedProfile {
                    profileView(profile: profile)
                }
            }
            .fullScreenCover(isPresented: $ui.showMessageScreen) {chatView}
            .sheet(item: $ui.showEventDetails) {event in
                NavigationStack { EventDetails(vm: vm, event: event)}
            }
        }
    }
}

//The Event Slots screens
extension EventsContainer {
    
    private var eventsPagerSection: some View {
        CustomTabPage(page: .meetingEvent, tabAction: $ui.showMessageScreen) {
            eventPages
        }
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 32 //Adds 24 padding on each side
        }
        .scrollIndicators(.hidden)
        .customScrollFade(height: 100, showFade: true)
    }
    
    private var eventPages: some View {
        TabView(selection: $tabProfile) {
            ForEach(vm.events) { eventProfile in
                eventSlot(eventProfile: eventProfile)
                    .tag(eventProfile)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .ignoresSafeArea(tabProfile == nil ? .all : []) //Fixes bug for screen layout
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) { screenWidth in
            imageSize = screenWidth - 32 //Adds 24 padding on each side
        }
    }
    
    private func eventSlot(eventProfile: EventProfile) -> some View {
        CustomTabPage(page: .meetingEvent, tabAction: $ui.showMessageScreen) {
            EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
            EventHeaderDetails(ui: ui, event: eventProfile.event) {openMaps(eventProfile)}
            EventMapView(event: eventProfile.event, imageSize: imageSize) {openMaps(eventProfile)}
            EventInfoView(ui: ui, event: eventProfile.event) {openMaps(eventProfile)}
        }
        .customScrollFade(height: 100, showFade: true)
        .task { await loadProfileImages(eventProfile.profile)}
    }
    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}

//The different Views
extension EventsContainer {
    
    @ViewBuilder
    private var chatView: some View {
        if let profile = tabProfile  {
            NavigationStack {
                ChatContainer(vm: ChatViewModel(defaults: vm.defaults, session: vm.sessionManager, chatRepo: vm.chatRepo, imageLoader: vm.imageLoader, eventProfile: profile))
            }
        } else {
            Text("No Tab Profile")
        }
    }
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(defaults: vm.defaults, s: vm.sessionManager, profile: profile, event: fetchEvent(profile), imageLoader: vm.imageLoader),
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.selectedProfile,
            dismissOffset: $ui.dismissOffset
        )
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
    
    private func fetchEvent(_ profile: UserProfile) -> UserEvent? {
        let eventProfile = vm.events.first { $0.profile.id == profile.id }
        return eventProfile?.event
    }
}
