//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.


import SwiftUI

struct EventsContainer: View {
    
    @State var vm: EventViewModel
    @State private var ui = EventUIState()
    
    @State private var profileImages: [String: [UIImage]] = [:]
    
    @State private var tabProfile: EventProfile?
    
    @State private var imageSize: CGFloat = 0
    @State private var disableMap: Bool = true
    @State private var mapEnabledScrollOffset: CGFloat?
    
    @State private var scrollTarget: String?
    
    var body: some View {

        if vm.events.isEmpty  {
            EventsPlaceholder()
        } else {
            NavigationStack {
                eventPages
                    .navigationDestination(item: $ui.selectedProfile) { profile in
                        profileView(profile: profile)
                    }
            }
            .animation(.easeInOut(duration: 0.2), value: ui.messageProfile)
            .fullScreenCover(item: $tabProfile) { eventProfile in
                chatView(eventProfile: eventProfile)
            }
            .sheet(item: $ui.showCantMakeIt) {eventProfile in
               CantMakeIt(vm: vm, eventProfile: eventProfile)
            }
        }
    }
}

//The Event Slots screens
extension EventsContainer {
    
    private var eventsPagerSection: some View {
        CustomTabPage(page: .meetingEvent, tabAction: $ui.deleteLater) {
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
            vm:ProfileViewModel(defaults: vm.defaults, s: vm.sessionManager, profile: profile, event: fetchEvent(profile), imageLoader: vm.imageLoader),
            profileImages: profileImages[profile.id] ?? [],
            mode: .viewProfile)
        .id(profile.id)
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
    
    private func fetchEvent(_ profile: UserProfile) -> UserEvent? {
        let eventProfile = vm.events.first { $0.profile.id == profile.id }
        return eventProfile?.event
    }
    
    private func buttonOverlay(eventProfile: EventProfile) -> some View {
        Button {
            tabProfile = eventProfile
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


extension EventsContainer {
    
    
    private func eventSlot(eventProfile: EventProfile) -> some View {
        CustomTabPage(page: .meetingEvent, tabAction: $ui.deleteLater) {
            VStack(spacing: 32) {
                EventImageView(ui: ui, eventProfile: eventProfile, imageSize: imageSize)
                if let acceptedTime = eventProfile.event.acceptedTime {
                    LargeClockView(targetTime: acceptedTime, showShadow: false) {}
                }
                EventDetailsContainer(ui: ui, event: eventProfile.event)
                    .opacity(disableMap ? 1 : 0.5)
                    .onTapGesture {
                        if !disableMap {
                            disableMap.toggle()
                        }
                    }
                
                EventMapView(event: eventProfile.event, imageSize: imageSize, disableMap: $disableMap) {openMaps(eventProfile)}
                    .id("Map")
                
                CoreInfoPage(event: eventProfile.event)
                    .opacity(disableMap ? 1 : 0.5)
                    .onTapGesture {
                        if !disableMap {
                            disableMap.toggle()
                        }
                    }
                
                Button {
                    ui.showCantMakeIt = eventProfile
                } label: {
                    Text("Can't Make It?")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.body(14, .bold))
                        .foregroundStyle(Color.accent)
                        .padding(.trailing, 24)
                }
                    
//                EventInfoView(ui: ui, event: eventProfile.event) {openMaps(eventProfile)}
            }
            .scrollTargetLayout()
            .padding(.bottom, 96)
            .onChange(of: disableMap) { oldValue, newValue in
                print(newValue)
                print(oldValue)
                if newValue == false {
                    print("Should Scroll")
                    scrollTarget = "Map"
                }
            }
        }
        .scrollPosition(id: $scrollTarget, anchor: .center)
        .customScrollFade(height: 100, showFade: true)
        .scrollClipDisabled()
        .task { await loadProfileImages(eventProfile.profile)}
        .overlay(alignment: .bottomTrailing) {
            buttonOverlay(eventProfile: eventProfile)
                .padding(.bottom, 96)
                .padding(.horizontal, 24)
                .opacity(disableMap ? 1 : 0.5)
                .onTapGesture {
                    if !disableMap {
                        disableMap.toggle()
                    }
                }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            guard disableMap == false else {
                mapEnabledScrollOffset = nil
                return
            }
            
            if mapEnabledScrollOffset == nil {
                mapEnabledScrollOffset = oldValue
            }

            if let enabledOffset = mapEnabledScrollOffset,
               abs(newValue - enabledOffset) > 10 { //Virtually as soon start scrolling disable Maps View
                disableMap = true
                mapEnabledScrollOffset = nil
            }
        }
        
    }
}
