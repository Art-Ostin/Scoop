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
    }
}

//1. Logic for ProfileContainer
extension InvitesContainer {
    
    private func inviteSlot(_ invite: EventProfile) -> some View {
        InviteSlot(
            vm: vm,
            eventProfile: invite,
            cardInset: cardInset,
            onRespond: { respond(invite, $0) },
            draft: vm.draftBinding(for: invite),
            openInvite: $ui.showQuickResponse
        )
        .containerRelativeFrame(.horizontal)
        .task { await vm.ensureImagesLoaded(for: invite.profile) }
    }
}

//Logic to respond to an Invite
extension InvitesContainer {
    
    
    private func respond(_ invite: EventProfile, _ respondType: ProfileResponse) {
        //Present the cover in the tap's own transaction — a Task hop before show() holds the
        //decline cross's takeoff back past the tap that triggered it
        let cover = responseCover?.show(respondType, inviteeName: invite.profile.name,
                                        acceptFlight: acceptFlight(invite, respondType))
        Task { await respondToProfile(invite.event.id, respondType, cover: cover) }
    }

    //Captured at the tap: the accept write is about to drop this invite's image cache, and
    //the first photo is both the cover's hero and the flight that lands it on the event
    //card. `invite.image` covers a cache that never filled — same loader, same first URL,
    //so the hand-off's pixel identity holds through the fallback too.
    private func acceptFlight(_ invite: EventProfile, _ respondType: ProfileResponse) -> AcceptFlightSource? {
        guard respondType == .accepted,
              let image = vm.profileImages[invite.profile.id]?.first ?? invite.image else { return nil }
        return AcceptFlightSource(image: image, eventId: invite.event.id)
    }

    //This deals with holding the respond screen cover & dismissing invitePopup behind
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse, cover: Int?) async {
        //Step 1: Minimum time the cover stays on screen. Decline holds longer — the cross
        //choreography (~1.05s clock to the absorb's end) must land before the exit begins.
        async let minDelay: Void = Task.sleep(for: respondType == .decline ? .seconds(2) : .seconds(3))

        try? await Task.sleep(for: BlurCoverMotion.coveredAt)
        ui.showQuickResponse = nil

        let responded: Bool
        do {
            try await vm.respond(to: respondType, eventId: eventId)
            responded = true
        } catch {
            responded = false // TODO: surface the failure once InAppNotification grows an error case
        }

        //Step 4: An accepted invite lands on its event — routed NOW, behind the still-opaque
        //wash, so the Events tab is mounted, paged to the event and scrolled to rest by the
        //time the cover's close measures its landing pad. id first, so a freshly mounted
        //Events tab already finds it on appear.
        if respondType == .accepted && responded {
            router.showEventId = eventId
            router.selectedTab = .events
            //The pad needs a beat to mount, page-jump and rest before close() measures it —
            //a write that acks near the 3s mark would otherwise hand close() a still-
            //settling pad and forfeit the flight to the fade. Runs behind the opaque wash.
            try? await Task.sleep(for: .milliseconds(450))
        }

        //Step 5: Once the minimum display time is done, close the cover — an accepted
        //invite's image flies into its event card as the wash clears; everything else fades
        try? await minDelay
        responseCover?.close(cover)
    }
}
