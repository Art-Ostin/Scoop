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

    //Local view state (profileMorph: invite-card image → profile pager hero morph, see ProfileMorph.swift)
    @State private var ui = InvitesUIState()
    @State private var profileMorph = ProfileMorphState()

    var body: some View {
        NavigationStack {
            TabScrollView(type: .invites, showEmptyView: vm.invites.isEmpty) {
                ForEach(vm.invites, id: \.self) { invite in
                    inviteCard(invite)
                }
            }
        }
        .profileMorphHost(profileMorph)
        
        //Different sub views of meetContainer
        .profileView(presentedID: ui.selectedProfile?.id, morph: profileMorph) {profileView}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileCover(responseType: $0)}
    }
}

//1. Logic for ProfileContainer
extension InvitesContainer {
    
    @ViewBuilder
    private var profileView: some View {
        if let profileID = ui.selectedProfile?.id, let eventProfile = vm.eventProfile(for: profileID) {
            ProfileContainer(
                vm: profileVM(for: eventProfile),
                profileImages: profileImages(for: eventProfile),
                mode: responseMode(eventProfile),
                onDismiss: {ui.selectedProfile = nil }
            )
        }
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
        vm.profileImages[eventProfile.profile.id] ?? eventProfile.image.map { [$0] } ?? []
    }
    
    private func responseMode(_ eventProfile: EventProfile) -> ProfileMode {
        let respondVM = vm.respondVM(for: eventProfile)

        return ProfileMode.respondToInvite(respondVM: respondVM) { type in
            respond(eventProfile.event.id, type)
        }
    }
    
    private func inviteCard(_ invite: EventProfile) -> some View {
        InviteCard(
            selectedProfile: $ui.selectedProfile,
            draft: vm.draftBinding(for: invite),
            eventProfile: invite,
            onRespond: {ui.showRespondPopup = invite.event.id}
        )
        .task { await vm.ensureImagesLoaded(for: invite.profile) }
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







extension View {
    
    func inviteView(presentedID: String?, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(ProfileOverlayModifier(slot: .invite, presentedID: presentedID, overlay: content))
    }
}


private struct ProfileOverlayModifier<Overlay: View>: ViewModifier {
    @Environment(ProfileOverlayPresenter.self) private var presenter: ProfileOverlayPresenter?
    let slot: ProfileOverlaySlotKind
    let presentedID: String?
    @ViewBuilder let overlay: () -> Overlay

    func body(content: Content) -> some View {
        content
            .onChange(of: presentedID, initial: true) { oldID, newID in
                guard let presenter else { return }
                if let newID {
                    presenter.show(slot, id: newID) { AnyView(overlay()) }
                } else if let oldID {
                    presenter.clear(slot, id: oldID)
                }
            }
            .onDisappear {
                if let presentedID { presenter?.clear(slot, id: presentedID) }
            }
    }
}
