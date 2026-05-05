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
                if let profile = ui.selectedProfile { profileView(profile: profile)}
                if let profileId = ui.showQuickInvite { timeAndPlaceView(profileId) }
            }
            if let response = ui.respondedToProfile { RespondedToProfileView(response: response)}
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

    private var invitesView: some View {
        VStack(spacing: 20) {
            titleAndTab
                .opacity(ui.showTimePopup ? (ui.hideInviteTitle ? 0.03 : 0.2) : 1)

            ForEach(vm.invites, id: \.self) { invite in
                InviteCard(
                    vm: vm.respondVM(for: invite, image: invite.image ?? UIImage()),
                    ui: ui,
                    eventProfile: invite,
                    openProfile: { openProfile($0) }) { profileId in
                        respond($0, .decline)
                    }
                    .task { await loadProfileImages(invite.profile) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .background(Color.background)
        .onPreferenceChange(HideInvitePreferenceKey.self) { newValue in
            ui.hideInviteTitle = newValue
        }
        .animation(.easeInOut(duration: 0.15), value: ui.hideInviteTitle)
    }
    
    
    private var titleAndTab: some View {
        ZStack(alignment: .top) {
            Text("Invites")
                .font(.custom("SFProRounded-Bold", size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                .padding(.leading, -4)
            
            TabInfoButton(showScreen: $ui.showDetails)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
}
//ProfileView Related
extension InvitesContainer {

    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = fetchEventProfile(profile),
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
        if let eventProfile = vm.invites.first(where: { $0.id == id }), let image = eventProfile.image {
            let inviteModel = InviteModel(profileId: eventProfile.profile.id, name: eventProfile.profile.name, image: image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    inviteModel: inviteModel,
                    defaults: vm.defaults
                ),
                showInvite: $ui.showQuickInvite,
                sendInvite: { responseDraft in
                    respond(id, .newInvite)
                })
        }
    }
}

//Function Helpers
extension InvitesContainer {
    
    private func openProfile(_ profile: UserProfile) {
        if ui.selectedProfile == nil {
            ui.dismissOffset = nil
            ui.selectedProfile = profile
        }
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        ui.profileImages[profile.id] = loadedImages
    }
    
    private func respond(_ id: String, _ type: ProfileResponse) {
        Task { try await respondToProfile(respondType: type, profileId: id)}
    }
    
    private func fetchEventProfile(_ profile: UserProfile) -> EventProfile? {
        vm.invites.first { $0.profile.id == profile.id }
    }
}
