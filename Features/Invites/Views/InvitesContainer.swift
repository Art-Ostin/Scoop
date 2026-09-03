//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI
import os

private let invitesLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Scoop", category: "invites")

struct InvitesContainer: View {
    
    //Injected
    @Environment(AppRouter.self) private var router
    @Environment(ResponseCoverPresenter.self) private var responseCover: ResponseCoverPresenter?
    let vm: InvitesViewModel

    //Local view state
    @State private var ui = InvitesUIState()
    

    @State var scrollProgress: Double = 0

    private var isSingleInvite: Bool { vm.invites.count == 1 }
    private var peek: CGFloat { isSingleInvite ? 0 : Spacing.gutter }
    private var cardInset: CGFloat? { isSingleInvite ? Spacing.gutter : nil }
    private var topPull: CGFloat { isSingleInvite ? -20 : -6 }
    
    
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
        .sheet(item: $ui.showInviteHistory) { eventProfile in
            InviteHistoryContainer(vm: vm, eventProfile: eventProfile)
        }
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
            openInvite: $ui.showQuickResponse,
            showInviteHistory: $ui.showInviteHistory
        )
        .containerRelativeFrame(.horizontal)
        .task { await vm.ensureImagesLoaded(for: invite.profile) }
    }
}

//Logic to respond to an Invite
extension InvitesContainer {
    
    
    private func respond(_ invite: EventProfile, _ respondType: ProfileResponse) {
        let cover = responseCover?.show(respondType, inviteeName: invite.profile.name,
                                        acceptFlight: acceptFlight(invite, respondType))
        Task { await respondToProfile(invite.event.id, respondType, cover: cover) }
    }
    
    private func acceptFlight(_ invite: EventProfile, _ respondType: ProfileResponse) -> AcceptFlightSource? {
        guard respondType == .accepted,
              let image = vm.profileImages[invite.profile.id]?.first ?? invite.image else { return nil }
        return AcceptFlightSource(image: image, eventId: invite.event.id)
    }

    //This deals with holding the respond screen cover & dismissing invitePopup behind
    private func respondToProfile(_ eventId: String, _ respondType: ProfileResponse, cover: Int?) async {
        async let minDelay: Void = Task.sleep(for: respondType == .decline ? .seconds(2) : .seconds(3))

        try? await Task.sleep(for: BlurCoverMotion.coveredAt)
        ui.showQuickResponse = nil

        let responded: Bool
        do {
            try await vm.respond(to: respondType, eventId: eventId)
            responded = true
        } catch {
            responded = false // TODO: surface the failure once InAppNotification grows an error case
            invitesLog.error("Respond \(String(describing: respondType)) failed for event \(eventId): \(String(describing: error))")
        }

        if respondType == .accepted && responded {
            router.showEventId = eventId
            router.selectedTab = .events
            try? await Task.sleep(for: .milliseconds(450))
        }
        try? await minDelay
        responseCover?.close(cover)
    }
}

