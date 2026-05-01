//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.


import SwiftUI

struct EventsContainer: View {

    @State var vm: EventViewModel
    @State private var ui = EventUIState()
    @State private var isScrollNavBarVisible: Bool = false
    
    @State private var profileImages: [String: [UIImage]] = [:]
    
    @State private var tabProfile: EventProfile?
    
    @State private var imageSize: CGFloat = 0
    @State private var disableMap: Bool = true
    @State private var mapEnabledScrollOffset: CGFloat?
    
    @State private var scrollTarget: String?
    @Binding var showMessageScreen: String?
    
    var body: some View {
        
        if vm.events.isEmpty  {
            EventsPlaceholder()
        } else {
            ZStack {
                TabView(selection: $tabProfile) {
                    ForEach(vm.events) { eventProfile in
                        eventSlot(eventProfile)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .ignoresSafeArea(ui.selectedProfile == nil ? .all : []) //Fixes bug for screen layout
                                
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
            .overlay(alignment: .topTrailing) {
                if vm.events.count > 1 && ui.selectedProfile == nil {
                    tabIndicator
                        .opacity(!isScrollNavBarVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.05), value: isScrollNavBarVisible)
                }
            }
            .measure(key: ImageSizeKey.self) { $0.size.width }
            .onPreferenceChange(ImageSizeKey.self) {imageSize = $0 - 32 } //Adds 16 padding on each side
            .onPreferenceChange(ScrollNavBarVisibleKey.self) { isScrollNavBarVisible = $0 }
            .onAppear { if tabProfile == nil { tabProfile = vm.events.first } }
        }
    }
}

//The Event Slots screens
extension EventsContainer {
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        EventSlotContainer(ui: ui, eventProfile: eventProfile, imageSize: imageSize) { openMaps(eventProfile)}
            .task{await loadProfileImages(eventProfile.profile)}
            .tag(eventProfile)
    }
    
    private func openMessageScreen (_ newValue: String?) {
        guard let id = newValue,
              let match = vm.events.first(where: { $0.id == id }) else { return }
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

//The different Views
extension EventsContainer {
    private func timeView(eventProfile: EventProfile) -> some View {
        VStack(spacing: 12) {
            if let time = eventProfile.event.acceptedTime {
                Text(FormatEvent.dayAndTime(time, wide: true, withHour: true))
                    .font(.custom("SFProRounded-Semibold", size: 22))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .kerning(0.4)
                LargeClockView(targetTime: time) {}
            }
        }
        .padding(16)
        .background (
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
    
    @ViewBuilder
    private func chatView(eventProfile: EventProfile) ->  some View {
        NavigationStack {
            ChatContainer(vm: ChatViewModel(defaults: vm.defaults, session: vm.sessionManager, chatRepo: vm.chatRepo, imageLoader: vm.imageLoader, eventProfile: eventProfile))
        }
    }
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(profile: profile, event: fetchEvent(profile), imageLoader: vm.imageLoader),
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.selectedProfile,
            dismissOffset: $ui.dismissOffset, mode: .viewProfile)
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
    
    
    private var tabIndicator: some View {
        HStack(spacing: 6) {
            ForEach(vm.events) { eventProfile in
                let isSelected = eventProfile.id == tabProfile?.id

                RoundedRectangle(cornerRadius: 100)
                    .frame(width: isSelected ? 10 : 5, height: 5)
                    .foregroundStyle(isSelected ? .black : .clear)
                    .stroke(100, lineWidth: 1, color: isSelected ? .clear : .black)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.background)
                .shadow(color: .black.opacity(0.05), radius: 1.5, x: 0, y: 3)
        )
        .surfaceShadow(.floating, strength: 1)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 24)
    }
}

