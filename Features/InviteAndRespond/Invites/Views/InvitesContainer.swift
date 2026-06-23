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

    // Respond-flow popup state, shared by the morph card (the pager) and its confirm alerts.
    @State private var respondUI = RespondPopupUIState()

    //Invite-card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()

    
    @State var imageSize: CGFloat = 0
    
    
    var body: some View {
        NavigationStack {
            AppScrollView(title: "Invites") {
                invitesView
            }
        }
    
        
        .profileMorphHost(profileMorph)
        .profileOverlay(id: ui.selectedProfile?.id) {
            if let profile = ui.selectedProfile { profileView(profile: profile) }
        }
        .profileOverlay(.cover, id: ui.respondedToProfile.map { "\($0)" }) {
            if let response = ui.respondedToProfile { RespondedToProfileView(response: response) }
        }
        .quickInviteMorph(openPopupId: $ui.showRespondPopup, style: .respond) { eventId in
            respondPager(eventId)
        } overlay: {
            respondOverlay
        }
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
                profileImages: vm.profileImages[eventProfile.profile.id] ?? eventProfile.image.map { [$0] } ?? [],
                mode: .respondToInvite(respondVM: respondVM) {responseType in
                    respond(eventProfile.event.id, responseType)
                },
                onDismiss: { ui.selectedProfile = nil }
            )
            .id(eventProfile.profile.id)
            .opacity(profileMorph.contentOpacity)
            .environment(profileMorph)
        }
    }

    @ViewBuilder
    private func respondPager(_ eventId: String) -> some View {
        if let eventProfile = vm.eventProfile(forEventId: eventId) {
            RespondContainer(
                vm: vm.respondVM(for: eventProfile),
                ui: respondUI,
                onHide: { ui.closeRespond() }
            ) { type in respond(eventId, type) }
        }
    }

    @ViewBuilder
    private var respondOverlay: some View {
        Color.clear.respondConfirmAlerts(ui: respondUI) { type in
            // The pager is still open during the confirm alert, so the driver holds the id.
            if let id = ui.showRespondPopup { respond(id, type) }
        }
    }

    @ViewBuilder
    private var invitesView: some View {
        if vm.invites.isEmpty {
            invitesPlaceHolder
        } else {
            InvitesView(ui: ui, vm: vm) { respond($0, .decline)}
                .padding(.top, 20)
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
        ui.closeRespond() //collapse the respond morph once a response is sent
        Task { try await respondToProfile(respondType: type, eventId: eventId)}
    }
    
    
    private func respondToProfile(respondType: ProfileResponse, eventId: String) async throws {
        
        
        
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = respondType
        try? await Task.sleep(for: .milliseconds(550))
        //Programmatic teardown behind the response cover — no flight, just reset.
        ui.selectedProfile = nil
        profileMorph.reset()
        try await vm.respond(to: respondType, eventId: eventId)
        try? await minDelay
        ui.respondedToProfile = nil
        if respondType == .accepted {
            router.selectedTab = .events
        }
    }
}
