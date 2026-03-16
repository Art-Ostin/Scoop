//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventView: View {
    
    let vm: EventViewModel
    let isFrozenEvent: Bool
    
    @Binding var showFrozenInfo: Bool
    
    @State private var ui = EventUIState()
    @State private var selection: String?
    @State private var profileImages: [String: [UIImage]] = [:]

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                ForEach(vm.events) {profile in
                    eventSlot(profile)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            if let profile = ui.selectedProfile {
                profileView(profile: profile)
            }
        }
        .colorBackground()
        .fullScreenCover(item: $ui.showMessageScreen) {chatView(profile: $0)}
        .sheet(item: $ui.showEventDetails) {eventDetailsView(event: $0) }
    }
}

extension EventView {
    
    private func eventSlot(_ profile: EventProfile) -> some View {
        EventSlot(vm: vm, ui: ui, imageSize: profile, dismissOffset: $dismissOffset, isFrozenEvent: isFrozenEvent, showfrozenInfo: $showFrozenInfo, eventProfile: <#EventProfile#>)
            .task { await loadProfileImages(profile) }
    }
    
    private func chatView(profile: EventProfile) -> some View {
        NavigationStack {
            ChatContainer(vm: ChatViewModel(session: vm.sessionManager, chatRepo: vm.chatRepo, profileModel: profile), eventVM: vm, profileModel: profile)
        }
    }
    
    private func profileView(profile: EventProfile) -> some View {
        ProfileView(vm: ProfileViewModel(defaults: vm.defaults, sessionManager: vm.sessionManager, profileModel: profile, imageLoader: vm.imageLoader), profileImages: profileImages[profile.id] ?? [], selectedProfile: $ui.selectedProfile, dismissOffset: $dismissOffset)
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
