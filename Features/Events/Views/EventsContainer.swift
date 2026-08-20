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
    @Binding var showEventId: String?
    @Binding var path: NavigationPath

    //Local View state
    @State private var ui = EventsUIState()
    @State private var userImage: UIImage? = nil
    @State private var scrollPosition = ScrollPosition(edge: .top)
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
                TabScrollView(type: .events, showEmptyView: vm.events.isEmpty, name: eventsTitle,
                              position: $scrollPosition) {
                    eventsList
                }
                .overlay(alignment: .bottomTrailing) { messageButton }
                .navigationDestination(for: EventProfile.self) { chatView(eventProfile: $0) }
            }
        }
        .ignoresSafeArea()
        .hideTabBar(!path.isEmpty)
        .onChange(of: showMessageScreen) {handleDeepLink(eventId: $1)}
        .onChange(of: showEventId) {focusEvent(id: $1)}
        .onChange(of: vm.events.count) {focusEvent(id: showEventId)} //A landing kept pending (event not listed yet) retries when the list catches up
        .onAppear {focusEvent(id: showEventId)} //A first tab switch mounts this container after the id was set — onChange never saw it
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
///
///A deep link is a CONTRACT, not a request: `.scrollPosition(id:)` is two-way, and a jump
///issued before the pager can honor it (the tab still attaching in the routing transaction,
///the target page freshly appended and not yet laid out) is silently reverted by the
///binding's next resting write-back — which the `.idle` hand-back would then copy into
///`selectedEventId`, erasing the deep link and landing accepted invites on the FIRST event.
///`pendingJump` latches the target until the pager actually rests on it: reverts are
///re-asserted, the hand-back stays quiet while pending, and a finger on the pager stands
///the latch down — never fight the user.
private struct EventsPager<Content: View>: View {

    //Injected
    @Binding var selectedEventId: String?
    @ViewBuilder let content: Content

    //Local view state
    @State private var pagedId: String?
    @State private var pendingJump: String? //A deep-link landing not yet achieved

    var body: some View {
        HorizontalScrollView(progress: .constant(0)) {
            content
        }
        .scrollPosition(id: $pagedId)
        .onScrollPhaseChange { _, phase in
            if phase == .interacting || phase == .decelerating { pendingJump = nil }
            guard phase == .idle else { return }
            if let pending = pendingJump {
                if pagedId == pending { pendingJump = nil } //The jump landed
                else { pagedId = pending }                  //Rested short of it — re-assert
                return
            }
            guard pagedId != selectedEventId else { return }
            selectedEventId = pagedId
        }
        //initial: true — a target already set when the pager first evaluates (an
        //empty→non-empty flip with a pending landing) must latch too, not become the baseline
        .onChange(of: selectedEventId, initial: true) { _, newId in
            //Already there (or cleared) — nothing to chase; drop any stale latch
            guard let newId, newId != pagedId else { pendingJump = nil; return }
            pendingJump = newId
            pagedId = newId //Deep links jump the pager
        }
        .onChange(of: pagedId) { _, newId in
            //A resting write-back that reverts the unachieved target is refused; the echo
            //of our own assignment (newId == pending) passes through untouched
            guard let pending = pendingJump, newId != pending else { return }
            pagedId = pending
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

    //A just-accepted invite: land the pager on its event (title and message button follow
    //selectedEventId). Runs behind the accept cover's still-opaque wash, so the vertical
    //rest happens unseen — and the accept flight's landing pad sits at its resting rect.
    private func focusEvent(id: String?) {
        guard let id else { return }
        //Not in the list yet: keep the id PENDING rather than consuming it — consuming on
        //absence would drop the landing forever; the events-count onChange retries it
        guard vm.event(id: id) != nil else { return }
        ui.selectedEventId = id
        scrollPosition.scrollTo(edge: .top)
        showEventId = nil
    }

    private func openMaps(_ eventProfile: EventProfile) {
        MapsRouter.openMaps(defaults: vm.defaults, item: eventProfile.event.location.mapItem, withDirections: true)
    }
}
