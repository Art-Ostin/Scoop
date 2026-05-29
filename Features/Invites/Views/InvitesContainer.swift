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

    var body: some View {
        AppScrollView(title: "Invites") {
            ZStack {
                invitesView
                
                if let profile = ui.selectedProfile { profileView(profile: profile)}

                if let eventId = ui.showQuickInvite {timeAndPlaceView(eventId)}
            }
            if let response = ui.respondedToProfile {RespondedToProfileView(response: response)}
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: ui.showTimePopup)
        .hideTabBar(hideBar: ui.hideTab)

        //The popups to respond to invite, from the invite card
        .respondItemCustomAlert(item: $ui.showAcceptPopup, type: .acceptInvite) { respond($0, .accepted) }
        .respondItemCustomAlert(item: $ui.showNewTimePopup, type: .sendNewTimes) { respond($0, .newTime) }
        .respondItemCustomAlert(item: $ui.showNewInvitePopup, type: .newInvite) { respond($0, .newInvite) }
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
                showInvite: $ui.showQuickInvite) {responseDraft in
                    respond(eventId, .newInvite)
                }
        }
    }

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
    
    @ViewBuilder
    private var invitesView: some View {
        if vm.invites.isEmpty {
            invitesPlaceHolder
        } else {
            InvitesView(ui: ui, vm: vm) { respond($0, .decline)}
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
