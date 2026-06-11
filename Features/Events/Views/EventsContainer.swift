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

    @State var openInfo = false
    @State var isAtTopOfScroll = true
    
    
    private var currentProfile: EventProfile? {
        vm.event(id: ui.selectedEventId) ?? vm.events.first
    }
    
    @Namespace var zoomNS
    @Binding var path: NavigationPath
    
    @State private var scrollProgress: Double = 0
    @State private var showInlineTitle = false
    
    @State var userImage: UIImage? = nil
    @State private var morph = ProfileMorphState()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                eventsRootView
                    .navigationDestination(for: EventProfile.self) {chatView(eventProfile: $0)}
            }
//            .overlay(alignment: .topTrailing) {
//                ScrollView(.horizontal) {
//                    HStack(spacing: 0) {
//                        ForEach(vm.events, id: \.self) { eventProfile in
//                            eventButton(eventProfile: eventProfile)
//                        }
//                    }
//                    .defaultScrollAnchor(.trailing)
//                    .padding(.bottom)
//                }
//            }
        }
        .profileMorphHost(morph)
        .profileOverlay(id: ui.selectedProfile?.id) {
            if let profile = ui.selectedProfile { profileView(profile: profile) }
        }
        .sheet(item: $ui.showCantMakeIt) {CantMakeIt(vm: vm, eventProfile: $0)}
        .getImageSize(imageSize: $ui.imageSize, horizontalPadding: 22) //16 padding, /6 inside padding on card
        .hideTabBar(hideBar: !path.isEmpty) //Chat: path-based, so it reappears the moment you pop (no flicker)
        .onChange(of: showMessageScreen) { _, newValue in
            handleDeepLink(eventId: newValue)
        }
        .task {userImage = try? await vm.fetchUserImage() }
    }
}

//The Event Slots screens
extension EventsContainer {
    
    @ViewBuilder
    private var eventsRootView: some View {
            if vm.events.isEmpty {
                EventsPlaceholder()
            } else {
                eventsScrollView
            }
        }
    
    private var eventsScrollView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(vm.events) { eventProfile in
                    eventPage(eventProfile)
                        .containerRelativeFrame(.horizontal)
                        .id(eventProfile.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $ui.selectedEventId)
        .scrollIndicators(.hidden)
        .colorBackground()
        .overlay(alignment: .bottomTrailing) { messageOverlay }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(showInlineTitle ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Events")
                    .font(.title(17, .semibold))
                    .opacity(showInlineTitle ? 1 : 0)
            }
        }
        .onChange(of: ui.selectedEventId) {
            showInlineTitle = false
            isAtTopOfScroll = true
        }
    }

    private func eventPage(_ eventProfile: EventProfile) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                if let name = vm.events.first(where: {$0.id == ui.selectedEventId})?.profile.name {
                    Text("Meeting \(name)")
                        .font(.title(28, .bold))
                        .opacity(showInlineTitle ? 0 : 1)
                }
                eventSlot(eventProfile)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 84)
        }
        .scrollIndicators(.hidden)
        //Check if at top of scroll
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top
        } action: { _, distanceFromTop in
            guard (ui.selectedEventId ?? vm.events.first?.id) == eventProfile.id else { return }
            isAtTopOfScroll = distanceFromTop <= 40
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showInlineTitle = distanceFromTop > 40
            }
        }
    }

    @ViewBuilder
    private func eventSlot(_ eventProfile: EventProfile) -> some View {
        if let userImage {
            EventSlot(ui: ui, eventProfile: eventProfile, imageSize: ui.imageSize, userImage: userImage) {
                openMaps(eventProfile)
            }
                    .task{await loadProfileImages(eventProfile.profile)}
        }
    }

    //Floats above the current event page and zooms into its chat
    @ViewBuilder
    private var messageOverlay: some View {
        if let eventProfile = currentProfile {
            NavigationLink(value: eventProfile) {
                Image("NewMessageIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(10)
                    .glassBackgroundIfAvailable(shape: Circle())
                    .expandHitArea(24)
            }
            .matchedTransitionSource(id: eventProfile.id, in: zoomNS)
            .padding(.bottom, 96)
            .padding(.horizontal, 24)
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
    
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm:ProfileViewModel(profile: profile, event: vm.event(forProfile: profile.id)?.event, imageLoader: vm.imageLoader, defaults: vm.defaults),
            profileImages: ui.profileImages[profile.id] ?? seedImages(for: profile),
            mode: .viewProfile,
            onDismiss: { ui.selectedProfile = nil })
        .id(profile.id)
        .opacity(morph.contentOpacity)
        .environment(morph)
    }

    //If the async profile images haven't landed yet, seed the pager with the tapped
    //card image so the morph destination exists (and is identical) on frame one.
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.event(forProfile: profile.id)?.image.map { [$0] } ?? []
    }
}


//Functions and Components
extension EventsContainer {
    
    //1. Load Images
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        ui.profileImages[profile.id] = loadedImages
    }
    
    private func handleDeepLink(eventId: String?) {
        guard let eventId, let eventProfile = vm.event(id: eventId) else { return }
        if path.isEmpty { path.append(eventProfile) }
        showMessageScreen = nil
    }
    
    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
    
    
    
    
    
    
}

//Formatting for event overlay
extension EventsContainer {
    
    private func eventButton(eventProfile: EventProfile) -> some View {
        Group {
            if isAtTopOfScroll {
                ScoopButton(shape: Capsule(), action: {openInfo = true}) {
                    Text(eventFormatter(event: eventProfile))
                        .font(.body(14, .medium))
                        .frame(height: 30)
                        .padding(.horizontal, 10)
                    
//                        .stroke(16, lineWidth: 1, color: Color(red: 0.55, green: 0, blue: 0.25))
                }
                .offset(y: -2)
                .transition(.scoopPop)
                .padding(.top, 16) //As its small icon, sits in correct position
                .padding(.horizontal, 16)
            }
        }
        .animation(.scoopPop, value: isAtTopOfScroll)
    }
    
    private func eventFormatter(event: EventProfile) -> String {
        let name = event.profile.name

        guard let date = event.event.acceptedTime else {
            return name
        }

        let month = date.formatted(.dateTime.month(.abbreviated))
        let monthDay = date.formatted(.dateTime.day(.defaultDigits))

        return "\(name) · \(monthDay) \(month)"
    }
}


/*
 private var eventTest: some View {
     Group {
         if isAtTopOfScroll {
             ScoopButton(shape: Capsule(), action: {openInfo = true}) {
                 Text("Arthur · 23 May")
                     .font(.body(14, .medium))
                     .frame(height: 30)
                     .padding(.horizontal, 10)
                 
//                        .stroke(16, lineWidth: 1, color: Color(red: 0.55, green: 0, blue: 0.25))
             }
             .offset(y: -2)
             .transition(.scoopPop)
             .padding(.top, 16) //As its small icon, sits in correct position
             .padding(.horizontal, 16)
         }
     }
     .animation(.scoopPop, value: isAtTopOfScroll)
 }

 */
