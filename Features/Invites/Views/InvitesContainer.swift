//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InvitesContainer: View {
    //Injected
    @Environment(AppRouter.self) private var router
    let vm: InvitesViewModel

    //Local view state
    @State private var ui = InvitesUIState()

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                TabScrollView(type: .invites, showEmptyView: vm.invites.isEmpty) {
                    ForEach(vm.invites, id: \.self) { invite in
                        inviteSlot(invite)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background { TimePickerWarmUp() }
        .fullScreenCover(isPresented: responseIsPresented) {
            if let response = ui.respondedToProfile {
                RespondedToProfileCover(responseType: response)
            }
        }
        .overlay {
            if let pending = ui.quickResponse {
//                inviteView(pending: pending)
            }
        }
    }
}

//1. Logic for ProfileContainer
extension InvitesContainer {
    
    private func profileView(for eventProfile: EventProfile) -> ProfileContainer {
        ProfileContainer(
            vm: profileVM(for: eventProfile),
            profileImages: profileImages(for: eventProfile),
            mode: responseMode(eventProfile)
        )
    }
    
    private func profileVM(for eventProfile: EventProfile) -> ProfileViewModel {
        ProfileViewModel(
            profile: eventProfile.profile,
            event: eventProfile.event,
            imageLoader: vm.imageLoader,
            defaults: vm.defaults
        )
    }
    
    private func profileImages(for eventProfile: EventProfile) -> [UIImage] {
        let loaded = vm.profileImages[eventProfile.profile.id] ?? []
        return loaded.isEmpty ? eventProfile.image.map { [$0] } ?? [] : loaded
    }
    
    private func responseMode(_ eventProfile: EventProfile) -> ProfileMode {
        let respondVM = vm.respondVM(for: eventProfile)

        return ProfileMode.respondToInvite(respondVM: respondVM) { type in
            respond(eventProfile.event.id, type)
        }
    }
    
    @ViewBuilder
    private func inviteSlot(_ invite: EventProfile) -> some View {
        InviteSlot(
            eventProfile: invite,
            draft: vm.draftBinding(for: invite),
            openInvite: $ui.quickResponse,
            profileImages: profileImages(for: invite),
            profileView: { AnyView(profileView(for: invite)) }
        )
            .task { await vm.ensureImagesLoaded(for: invite.profile) }
    }

    private var responseIsPresented: Binding<Bool> {
        Binding(
            get: { ui.respondedToProfile != nil },
            set: { if !$0 { ui.respondedToProfile = nil } }
        )
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
    }
}
