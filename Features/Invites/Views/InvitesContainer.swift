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

    var body: some View {
        ZStack {
            invitesView

            if let profile = ui.selectedProfile { profileView(profile: profile)}

            if let response = ui.respondedToProfile {RespondedToProfileView(response: response)}
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

        //The popups to respond to invite, from the invite card
        .respondItemCustomAlert(item: $ui.showAcceptPopup, type: .acceptInvite) { respond($0, .accepted) }
        .respondItemCustomAlert(item: $ui.showNewTimePopup, type: .sendNewTimes) { respond($0, .newTime) }
    }
}

extension InvitesContainer {

    //Different Views on cotnainer
    
    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = vm.eventProfile(for: profile.id),
           let respondVM = vm.respondVMs[eventProfile.event.id] {
            ProfileView(
                vm: ProfileViewModel(
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader,
                    defaults: vm.defaults
                ),
                profileImages: vm.profileImages[eventProfile.profile.id] ?? [],
                mode: .respondToInvite(respondVM: respondVM) {responseType in
                    respond(eventProfile.event.id, responseType)
                },
                onDismiss: { ui.selectedProfile = nil }
            )
            .id(eventProfile.profile.id)
            .zIndex(1)
            .transition(.move(edge: .bottom))
        }
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
        Task { try await respondToProfile(respondType: type, eventId: eventId)}
    }
    
    
    private func respondToProfile(respondType: ProfileResponse, eventId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        ui.selectedProfile = nil
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
