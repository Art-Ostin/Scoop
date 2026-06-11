//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InvitesContainer: View {
    
    @Environment(AppRouter.self) private var router
    
    @State var ui = InvitesUIState()
    @State var vm: InvitesViewModel

    @State private var morphInviteId: String?
    @State private var pendingInvite: (() -> Void)?
    // Respond-flow popup state, shared by the morph card (the pager) and its confirm alerts.
    @State private var respondUI = RespondPopupUIState()

    //Invite-card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()

    var body: some View {
        ZStack {
            invitesView

        }
        .profileMorphHost(profileMorph)
        //Both present above the root TabView: the real tab bar sits behind the
        //profile (revealed + dimmed during the zoom dismissal) and the response
        //cover physically occludes it.
        .profileOverlay(id: ui.selectedProfile?.id) {
            if let profile = ui.selectedProfile { profileView(profile: profile) }
        }
        .profileOverlay(.cover, id: ui.respondedToProfile.map { "\($0)" }) {
            if let response = ui.respondedToProfile { RespondedToProfileView(response: response) }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: ui.showTimePopup)
        .quickInviteMorph(
            iconId: $ui.showQuickInvite,
            morphInviteId: $morphInviteId,
            hideCard: pendingInvite != nil,
            showsHideButton: true,
            style: .plainCard.tinted(.appCanvas)
        ) { eventId in
            timeAndPlaceView(eventId)
        } overlay: {
            MorphConfirmAlert(pending: $pendingInvite)
        }

        //The respond popup morphs out of the tapped invite card's invite button.
        .quickInviteMorph(
            iconId: $ui.showRespondPopup,
            morphInviteId: $ui.respondMorphId,
            style: .respond
        ) { eventId in
            respondPager(eventId)
        } overlay: {
            respondOverlay
        }

        //The popups to respond to invite, from the invite card
        .respondItemCustomAlert(item: $ui.showAcceptPopup, type: .acceptInvite) { respond($0, .accepted) }
        .respondItemCustomAlert(item: $ui.showNewTimePopup, type: .sendNewTimes) { respond($0, .newTime) }
    }
}

extension InvitesContainer {

    //Different Views on cotnainer
    
    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = vm.eventProfile(for: profile.id) {
            let respondVM = vm.respondVM(for: eventProfile)
            ProfileView(
                vm: ProfileViewModel(
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader,
                    defaults: vm.defaults
                ),
                //Seed with the tapped card image if the async set hasn't landed, so
                //the morph destination exists (and is identical) on frame one.
                profileImages: vm.profileImages[eventProfile.profile.id] ?? eventProfile.image.map { [$0] } ?? [],
                mode: .respondToInvite(respondVM: respondVM) {responseType in
                    respond(eventProfile.event.id, responseType)
                },
                onDismiss: { ui.selectedProfile = nil }
            )
            .id(eventProfile.profile.id)
            //Cross-fades in the same 0.3s transaction as the invite image flight.
            .opacity(profileMorph.contentOpacity)
            //Rendered at the app root, outside this container's environment.
            .environment(profileMorph)
        }
    }

    @ViewBuilder
    private func respondPager(_ eventId: String) -> some View {
        if let eventProfile = vm.eventProfile(forEventId: eventId) {
            RespondPager(
                vm: vm.respondVM(for: eventProfile),
                ui: respondUI,
                showPopup: respondShowPopup
            ) { type in respond(eventId, type) }
        }
    }

    @ViewBuilder
    private var respondOverlay: some View {
        Color.clear.respondConfirmAlerts(ui: respondUI) { type in
            if let id = ui.respondMorphId { respond(id, type) }
        }
    }

    private var respondShowPopup: Binding<Bool> {
        Binding(get: { ui.showRespondPopup != nil },
                set: { if !$0 { ui.showRespondPopup = nil } })
    }

    @ViewBuilder
    private func timeAndPlaceView(_ eventId: String) -> some View {
        //1. First fetch the correct EventProfile by event id
        if let eventProfile = vm.eventProfile(forEventId: eventId), let image = eventProfile.image {
            let inviteModel = InviteModel(profileId: eventProfile.profile.id, name: eventProfile.profile.name, image: image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    inviteModel: inviteModel,
                    defaults: vm.defaults
                ),
                sendInvite: { _ in respond(eventId, .newInvite) },
                requestConfirm: { pendingInvite = $0 }
            )
        }
    }
    
    @ViewBuilder
    private var invitesView: some View {
        NavigationStack {
            AppScrollView(title: "Invites") {
                if vm.invites.isEmpty {
                    invitesPlaceHolder
                } else {
                    InvitesView(ui: ui, vm: vm) { respond($0, .decline)}
                        .padding(.top, 20)
                }
            }
        }
    }
    
    private var invitesPlaceHolder: some View {
        VStack(spacing: 96) {
            Text("Any invites received appear here")
                .font(.title(20, .medium))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Image("CoolGuys")
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(width: 250, height: 250)
        }
        .padding(.top, 72)
    }
}


extension InvitesContainer {
    //Different functions used in container
    private func respond(_ eventId: String, _ type: ProfileResponse) {
        ui.showRespondPopup = nil //collapse the respond morph once a response is sent
        Task { try await respondToProfile(respondType: type, eventId: eventId)}
    }
    
    
    private func respondToProfile(respondType: ProfileResponse, eventId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        //Programmatic teardown behind the response cover — no flight, just reset.
        ui.selectedProfile = nil
        profileMorph.reset()
        try await respondToProfileAction(respondType: respondType, eventId: eventId)
        try? await minDelay
        ui.respondedToProfile = nil
        if respondType == .accepted {
            router.selectedTab = .events
        }
    }
    
    private func respondToProfileAction(respondType: ProfileResponse, eventId: String) async throws {
        switch respondType {
        case .accepted:  try await vm.accept(eventId: eventId)
        case .newTime:   try await vm.sendNewTime(eventId: eventId)
        case .newInvite: try await vm.sendNewEvent(eventId: eventId)
        case .decline:   try await vm.decline(eventId: eventId)
        }
    }
}
