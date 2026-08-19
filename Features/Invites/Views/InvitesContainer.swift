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
            onRespond: { respond(invite.event.id, $0, name: invite.profile.name)},
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
                respond(invite.id, response, name: invite.profile.name)
        }
    }
}

//Logic to respond to an Invite
extension InvitesContainer {
    
    
    private func respond(_ eventId: String, _ respondType: ProfileResponse, name: String) {
        //Present the cover in the tap's own transaction — a Task hop before show() holds the
        //decline cross's takeoff back past the tap that triggered it
        let cover = responseCover?.show(respondType, inviteeName: name)
        Task { await respondToProfile(eventId, respondType, cover: cover) }
    }

    //This deals with holding the respond screen cover & dismissing invitePopup behind
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse, cover: Int?) async {
        //Step 1: Minimum time the cover stays on screen. Decline holds longer — the cross
        //choreography (~1.05s clock to the absorb's end) must land before the exit begins.
        async let minDelay: Void = Task.sleep(for: respondType == .decline ? .seconds(2) : .milliseconds(850))

        //Step 2: Once the cover is opaque, dismiss the respond popup beneath it. Held past the
        //cover's own fade-in — dismissing mid-morph shows the popup collapsing through it.
        try? await Task.sleep(for: BlurCoverMotion.coveredAt)
        ui.showQuickResponse = nil

        //Step 3: Actually respond to Invite. A failed write leaves the invite in place, so the
        //cover just fades back to the untouched list instead of landing on an event that isn't there.
        let responded: Bool
        do {
            try await vm.respond(to: respondType, eventId: eventId)
            responded = true
        } catch {
            responded = false // TODO: surface the failure once InAppNotification grows an error case
        }

        //Step 4: Once the minimum display time is done, fade the cover back out
        try? await minDelay
        responseCover?.close(cover)

        //Step 5: An accepted invite lands on its event — id first, so a freshly
        //mounted Events tab already finds it on appear
        if respondType == .accepted && responded {
            router.showEventId = eventId
            router.selectedTab = .events
        }
    }
}
