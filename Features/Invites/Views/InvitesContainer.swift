//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InvitesContainer: View {
    
    @Environment(\.tabSelection) var selectedTab

    @State var ui = InvitesUIState()
    @State var vm: InvitesViewModel

    var body: some View {
        ZStack {
            if vm.invites.isEmpty {
                InvitesPlaceholder()
            } else {
                
                invitesView
                
                if let profile = ui.selectedProfile {
                    profileView(profile: profile)
                }
                
                if let profileId = ui.showQuickInvite {
                    timeAndPlaceView(profileId)
                }
                
            }
            
            if let response = ui.respondedToProfile {
                RespondedToProfileView(response: response)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onPreferenceChange(IsTimeOpen.self) { newValue in
            ui.showTimePopup = newValue
        }
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
    private var invitesView: some View {
        InvitesView(ui: ui, vm: vm)
    }
    
    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = vm.eventProfile(for: profile.id),
           let respondVM = vm.respondVMs[eventProfile.profile.id] {
            ProfileView(
                vm: ProfileViewModel(
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader,
                    defaults: vm.defaults
                ),
                profileImages: ui.profileImages[eventProfile.profile.id] ?? [],
                selectedProfile: $ui.selectedProfile,
                dismissOffset: $ui.dismissOffset,
                mode: .respondToInvite(respondVM: respondVM) {responseType in
                    respond(eventProfile.profile.id, responseType)
                }
            )
            .id(eventProfile.profile.id)
            .zIndex(1)
            .transition(.move(edge: .bottom))
        }
    }

    @ViewBuilder
    private func timeAndPlaceView(_ id: String) -> some View {
        //1. First fetch the correctProfile, as view is triggered by passing in ID
        if let eventProfile = vm.eventProfile(for: id), let image = eventProfile.image {
            let inviteModel = InviteModel(profileId: eventProfile.profile.id, name: eventProfile.profile.name, image: image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    inviteModel: inviteModel,
                    defaults: vm.defaults
                ),
                showInvite: $ui.showQuickInvite) {responseDraft in
                    respond(id, .newInvite)
                }
        }
    }
    
    //Different functions used in container
    private func respond(_ id: String, _ type: ProfileResponse) {
        Task { try await respondToProfile(respondType: type, profileId: id)}
    }
    private func respondToProfile(respondType: ProfileResponse, profileId: String) async throws {
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        ui.selectedProfile = nil
        try await respondToProfileAction(respondType: respondType, profileId: profileId)
        try? await minDelay
        ui.respondedToProfile = nil
        if respondType == .accepted {
            selectedTab.wrappedValue = .events
        }
    }
    private func respondToProfileAction(respondType: ProfileResponse, profileId: String) async throws {
        switch respondType {
        case .accepted:  try await vm.accept(profileId: profileId)
        case .newTime:   try await vm.sendNewTime(profileId: profileId)
        case .newInvite: try await vm.sendNewEvent(profileId: profileId)
        case .decline:   try await vm.decline(profileId: profileId)
        }
    }
}
