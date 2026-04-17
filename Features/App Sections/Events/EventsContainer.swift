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
    @State private var disableMap: Bool = true
    
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
            .animation(.easeInOut(duration: 1), value: disableMap)
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
            VStack(spacing: 32) {
                EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                if let time = eventProfile.event.acceptedTime { //For testing change later
                    LargeClockView(targetTime: Calendar.current.date(byAdding: .hour, value: 7, to: .now)!, showShadow: false) {}
                }
                EventDetailsView(ui: ui, event: eventProfile.event)                
                
                EventMapView(event: eventProfile.event, imageSize: imageSize, disableMap: $disableMap) {openMaps(eventProfile)}
                CoreInfoPage(event: eventProfile.event)
                Text("Can't Make It?")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.body(14, .bold))
                    .foregroundStyle(Color.accent)
                    .padding(.trailing, 24)
                    
//                EventInfoView(ui: ui, event: eventProfile.event) {openMaps(eventProfile)}
            }
            .padding(.bottom, 96)
        }
        .customScrollFade(height: 100, showFade: true)
        .scrollClipDisabled()
        .task { await loadProfileImages(eventProfile.profile)}
        .overlay(alignment: .bottomTrailing) {
            buttonOverlay
                .padding(.bottom, 96)
                .padding(.horizontal, 24)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            if newValue > 30 {
                if disableMap == false {
                    disableMap = true
                }
            }
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
    
    private var buttonOverlay: some View {
        Button {
            
        } label: {
            Image("NewMessageIcon") //NewMessageIcon
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .font(.body(17, .bold))
                .padding(10)
                .glassIfAvailable(isClear: true)
                .padding(24) //Expands Tap Area
                .contentShape(Rectangle())
                .padding(-24)
        }
    }
}
