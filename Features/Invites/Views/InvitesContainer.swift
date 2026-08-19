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

    @State var scrollProgress: Double = 0

    //A lone invite has no neighbour to leave room for: the pager stops carving a peek out of
    //itself and the card runs out to the nav title's edge instead
    private var isSingleInvite: Bool { vm.invites.count == 1 }
    private var peek: CGFloat { isSingleInvite ? 0 : Spacing.gutter }
    ///nil leaves AppImage's own invite inset in charge — only the lone card overrides it
    private var cardInset: CGFloat? { isSingleInvite ? Spacing.gutter : nil }
    private var topPull: CGFloat { isSingleInvite ? -20 : -6 } //Geometry: pulls the column up under titlePadding, the lone card higher still

    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                TabScrollView(type: .invites, showEmptyView: vm.invites.isEmpty) {
                    HorizontalScrollView(progress: $scrollProgress, peek: peek) {
                        ForEach(vm.invites, id: \.self) { invite in
                            inviteSlot(invite)
                        }
                    }
                    .scrollClipDisabled()
                    .padding(.top, topPull)
                    .animation(.move, value: isSingleInvite) //Answering the second-to-last invite settles the card wider rather than snapping
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
            cardInset: cardInset,
            onRespond: { respond(invite.event.id, $0)},
            draft: vm.draftBinding(for: invite),
            openInvite: $ui.showQuickResponse
        )
        .containerRelativeFrame(.horizontal)
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
        //Present the cover in the tap's own transaction — a Task hop before show() holds the
        //decline cross's takeoff back past the tap that triggered it
        let cover = responseCover?.show(respondType)
        Task { await respondToProfile(eventId, respondType, cover: cover) }
    }

    //This deals with holding the respond screen cover & dismissing invitePopup behind
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse, cover: Int?) async {
        //Step 1: Minimum time the cover stays on screen. Decline holds longer — the cross
        //choreography (1.15s of flight) must land and settle before the exit begins.
        async let minDelay: Void = Task.sleep(for: respondType == .decline ? .seconds(2) : .milliseconds(850))

        //Step 2: After 0.2s, dismiss the profile & invite popups beneath the respond cover
        try? await Task.sleep(for: .milliseconds(200))
        //Find Out how to dismiss profile and popup here

        //Step 3: Actually respond to Invite
        try? await vm.respond(to: respondType, eventId: eventId)

        //Step 4: Once the minimum display time is done, fade the cover back out
        try? await minDelay
        responseCover?.close(cover)

        //Step 5: If Accepted go to the 'accepted' Tab
        if respondType == .accepted {
            router.selectedTab = .events
        }
    }
}


/*
 .overlay(alignment: .topTrailing) {
     PageIndicator(count: vm.invites.count, progress: scrollProgress)
         .scaleEffect(0.7)
         .offset(y: -24)
         .padding(.horizontal)
 }
 */
