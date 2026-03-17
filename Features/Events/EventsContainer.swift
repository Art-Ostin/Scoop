//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventsContainer: View {
    
    @State var vm: EventViewModel
    @State private var ui = EventUIState()
        
    @State private var selectedProfile: EventProfile?
    @State private var profileImages: [String: [UIImage]] = [:]
    

    var body: some View {
        
        if vm.events.isEmpty  {
            EventsPlaceholder()
        } else {
            ZStack {
                profilesTabView
                
                if let profile = ui.selectedProfile {
                    profileView(profile: profile)
                }
            }
            .colorBackground()
            .fullScreenCover(isPresented: $ui.showMessageScreen) {
                if let profile = selectedProfile {chatView(profile: profile) }
            }
            .sheet(item: $ui.showEventDetails) {eventDetailsView(event: $0) }
        }
    }
}

extension EventsContainer {
    
    private var profilesTabView: some View {
        TabView(selection: $selectedProfile) {
            ForEach(vm.events) {profile in
                eventSlot(profile)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
    
    private func eventSlot(_ profile: EventProfile) -> some View {
        EventSlotContainer(vm: vm, eventProfile: profile, ui: ui)
            .task { await loadProfileImages(profile) }
    }
    
    private func chatView(profile: EventProfile) -> some View {
        NavigationStack {
            ChatContainer(vm: ChatViewModel(defaults: vm.defaults, session: vm.sessionManager, chatRepo: vm.chatRepo, imageLoader: vm.imageLoader, eventProfile: profile))
        }
    }
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(defaults: vm.defaults, s: vm.sessionManager, profile: profile, imageLoader: vm.imageLoader),
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.selectedProfile,
            dismissOffset: $ui.dismissOffset
        )
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    private func eventDetailsView(event: UserEvent) -> some View {
        NavigationStack {
            EventDetails(vm: vm, event: event)
        }
    }
    
    private func loadProfileImages(_ profile: EventProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
}
