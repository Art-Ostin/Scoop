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

    var body: some View {
        if vm.events.isEmpty  {
            EventsPlaceholder()
        } else {
            ZStack {
                eventsScrollView

                if let profile = ui.selectedProfile {
                    profileView(profile: profile)
                }
            }
            .fullScreenCover(item: $ui.messageProfile, onDismiss: {showMessageScreen = nil}) { eventProfile in
                chatView(eventProfile: eventProfile)
            }
            .sheet(item: $ui.showCantMakeIt) {eventProfile in
               CantMakeIt(vm: vm, eventProfile: eventProfile)
            }
            .onChange(of: showMessageScreen) { _, newValue in
                openMessageScreen(newValue)
            }
            .overlay(alignment: .top) {
                if vm.events.count > 1 && ui.selectedProfile == nil {
                    tabIndicator
                        .opacity(ui.isScrollNavBarVisible ? 0 : 1)
                        .animation(.easeInOut(duration: 0.05), value: ui.isScrollNavBarVisible)
                }
            }
            .measure(key: ImageSizeKey.self) { $0.size.width }
            .onPreferenceChange(ImageSizeKey.self) { ui.imageSize = $0 - 32 } //Adds 16 padding on each side
            .onPreferenceChange(ScrollNavBarVisibleKey.self) { ui.isScrollNavBarVisible = $0 }
            .background(Color.appCanvas.ignoresSafeArea())
        }
    }
}

//The Event Slots screens
extension EventsContainer {
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        EventSlotContainer(ui: ui, eventProfile: eventProfile, imageSize: ui.imageSize) { openMaps(eventProfile)}
            .task{await loadProfileImages(eventProfile.profile)}
            .tag(eventProfile)
    }
    
    private func openMessageScreen (_ newValue: String?) {
        guard let match = vm.event(id: newValue) else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            ui.messageProfile = match
        }
    }
    
    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}

//The tab indicator
extension EventsContainer {
    
    private var tabIndicator: some View {
        HStack(spacing: 6) {
            ForEach(vm.events) { eventProfile in
                let isSelected = eventProfile.id == currentProfile?.id

                RoundedRectangle(cornerRadius: 100)
                    .frame(width: isSelected ? 10 : 5, height: 5)
                    .foregroundStyle(isSelected ? .black : .clear)
                    .stroke(100, lineWidth: 1, color: isSelected ? .clear : .black)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.appCanvas)
                .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
        )
        .surfaceShadow(.floating, strength: 1)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 24)
    }
    
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
        NavigationStack {
            ChatContainer(vm: vm.makeChatViewModel(for: eventProfile), isEvent: true)
        }
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





