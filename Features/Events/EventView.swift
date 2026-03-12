//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI
import FirebaseFunctions


struct EventView: View {
    
    @State var ui = EventUIState()
    
    let vm: EventViewModel
    
    @State var showEventDetails: Bool = false
    @State var selection: String?
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [String : [UIImage]] = [ : ]
    
    @Binding var showFrozenInfo: Bool
    let isFrozenEvent: Bool
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea().background(Color.background)
        .fullScreenCover(item: $ui.showMessageScreen) {chatView(profile: $0)}
        .sheet(item: $ui.showEventDetails) { eventDetailsView(event: $0) }
    }
}

extension EventView {
    
    private func eventSlot(_ profile: ProfileModel) -> some View {
        EventSlot(vm: vm, ui: ui, profileModel: profile, dismissOffset: $dismissOffset, isFrozenEvent: isFrozenEvent, showfrozenInfo: $showFrozenInfo)
            .task { await loadProfileImages(profile) }
    }
    
    private func chatView(profile: ProfileModel) -> some View {
        NavigationStack {
            ChatContainer(vm: ChatViewModel(session: vm.sessionManager, chatRepo: vm.chatRepo, profileModel: profile), eventVM: vm, profileModel: profile)
        }
    }
    
    private func profileView(profile: ProfileModel) -> some View {
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
    
    private func loadProfileImages(_ profile: ProfileModel) async {
        let loadedImages = await vm.loadImages(profileModel: profile)
        profileImages[profile.id] = loadedImages
    }
}
