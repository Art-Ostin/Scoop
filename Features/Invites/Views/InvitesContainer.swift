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
    @Environment(ResponseCoverPresenter.self) private var responseCover: ResponseCoverPresenter?
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
        .overlay {
            if let invite = ui.showQuickResponse {
                respondPoup(invite)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .hideTabBar(ui.showQuickResponse != nil)
    }
}

//1. Logic for ProfileContainer
extension InvitesContainer {
    
    private func inviteSlot(_ invite: EventProfile) -> some View {
        InviteSlot(
            vm: vm,
            eventProfile: invite,
            onRespond: { respond(invite.event.id, $0)},
            draft: vm.draftBinding(for: invite),
            openInvite: $ui.showQuickResponse
        )
        .task { await vm.ensureImagesLoaded(for: invite.profile) }
    }
    
    private func respondPoup(_ invite: EventProfile) -> some View {
        let images = vm.profileImages[invite.profile.id] ?? []
        let timeAndPlaceVM = TimeAndPlaceViewModel(profileId: invite.profile.id, defaults: vm.defaults)
        
       return RespondInviteContainer(
            images: images,
            vm: vm.respondVM(for: invite),
            timeAndPlaceVM: timeAndPlaceVM,
            showInvitePopup: $ui.showQuickResponse) { response in
                respond(invite.id, response)
        }
    }
}

//Logic to respond to an Invite
extension InvitesContainer {
    
    
    private func respond(_ eventId: String, _ respondType: ProfileResponse) {
        Task { await respondToProfile(eventId, respondType)}
    }
    
    //This deals with presenting the respond screen cover & dismissing invitePopup behind
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse) async {
        //Step 1: Min time for whole process 0.85 seconds
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        
        //Step 2: Fade the response cover in on the root plane, above the tab bar
        responseCover?.response = respondType
        
        //Step 3: After 0.2s, dismiss the profile & invite popups beneath the respond cover
        try? await Task.sleep(for: .milliseconds(200))
        //Find Out how to dismiss profile and popup here
        
        //Step 4: Actually respond to Invite
        try? await vm.respond(to: respondType, eventId: eventId)
        
        //Step 5: Once minimum of 0.85 seconds done, fade the cover back out
        try? await minDelay
        responseCover?.response = nil

        //Step 6: If Accepted go to the 'accepted' Tab
        if respondType == .accepted {
            router.selectedTab = .events
        }
    }
}
