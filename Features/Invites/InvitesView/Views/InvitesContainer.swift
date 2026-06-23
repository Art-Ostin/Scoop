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
        .profileView(presentedID: ui.selectedProfile?.id) {profileView()}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileView(responseType: $0)}
        
        
        
        
        .quickInvite(openPopupId: $ui.showRespondPopup, style: .respond) { eventId in
            respondContainer(eventId)
        } overlay: {
            respondOverlay
        }
    }
}

//Different Views
extension InvitesContainer {
    //1. Constructor for opening and displaying Profile View
    @ViewBuilder
    private func profileView() -> some View {
        if let profile = ui.selectedProfile, let eventProfile = vm.eventProfile(for: profile.id) {
            ProfileView(
                vm: profileVM(eventProfile),
                profileImages: fetchProfileImages(eventProfile),
                mode: respondMode(eventProfile),
                onDismiss: { ui.selectedProfile = nil}
            )
            .id(eventProfile.profile.id)
            .opacity(profileMorph.contentOpacity)
            .environment(profileMorph)
        }
    }
    
    private func profileVM(_ eventProfile: EventProfile) -> ProfileViewModel {
        ProfileViewModel(
            profile: eventProfile.profile,
            event: eventProfile.event,
            imageLoader: vm.imageLoader,
            defaults: vm.defaults
        )
    }
    
    private func fetchProfileImages(_ eventProfile: EventProfile) -> [UIImage] {
        vm.profileImages[eventProfile.profile.id] ?? eventProfile.image.map { [$0] } ?? []
    }
    
    private func respondMode(_ eventProfile: EventProfile) -> ProfileMode {
        let respondVM = vm.respondVM(for: eventProfile)

        return ProfileMode.respondToInvite(respondVM: vm.respondVM(for: eventProfile)) { type in
            respond(eventProfile.event.id, type)
        }
    }

    @ViewBuilder //2. Constructor for opening and displaying respondContainer
    private func respondContainer(_ eventId: String) -> some View {
        if let eventProfile = vm.eventProfile(forEventId: eventId) {
            RespondContainer(
                vm: vm.respondVM(for: eventProfile),
                ui: respondUI,
                onHide: {ui.showRespondPopup = nil},
                onResponse: { type in respond(eventId, type)}
            )
        }
    }
}

extension InvitesContainer {

    
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
            InvitesPlaceholder()
        } else {
            InvitesView(ui: ui, vm: vm) { respond($0, .decline)}
                .padding(.top, 20)
        }
    }
}



//Logic to respond to an Invite
extension InvitesContainer {
    
    private func respond(_ eventId: String, _ respondType: ProfileResponse) {
        Task { await respondToProfile(eventId, respondType)}
    }
    
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse) async {
        //Step 1: Min time for whole process 0.85 seconds
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        
        //Step 2: Show respond fullScreencover. Animation to open takes 0.2
        ui.respondedToProfile = respondType
        
        //Step 3: After 0.2s, dismiss the profile & invite popups beneath the respond cover
        try? await Task.sleep(for: .milliseconds(200))
        hideProfileAndInviteInBackground()
        
        //Step 4: Actually respond to Invite
        try? await vm.respond(to: respondType, eventId: eventId)
        
        //Step 5: Once minimum of 0.85 seconds done, dismiss the screen
        try? await minDelay
        ui.respondedToProfile = nil

        //Step 6: If Accepted go to the 'accepted' Tab
        if respondType == .accepted {
            router.selectedTab = .events
        }
    }
    
    private func hideProfileAndInviteInBackground() {
        ui.showRespondPopup = nil
        ui.selectedProfile = nil
        profileMorph.reset()
    }
}
