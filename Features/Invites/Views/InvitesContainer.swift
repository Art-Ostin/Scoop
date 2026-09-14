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
    @State private var isAtTopOfScroll = true
    @State private var scrollPosition = ScrollPosition()

    @State var scrollProgress: Double = 0
    
    @Namespace var infoZoom

    private var isSingleInvite: Bool { vm.invites.count == 1 }
    private var peek: CGFloat { isSingleInvite ? 0 : Spacing.gutter }
    private var cardInset: CGFloat? { isSingleInvite ? Spacing.gutter : nil }
    private var topPull: CGFloat { isSingleInvite ? -20 : -6 }
    
    
    var body: some View {
        ZoomNavigationStack {
            NavigationStack {
                TabScrollView(type: .invites, showEmptyView: vm.invites.isEmpty) {
                    HorizontalScrollView(progress: $scrollProgress, position: $scrollPosition, peek: peek) {
                        ForEach(vm.invites, id: \.self) { invite in
                            inviteSlot(invite)
                                .id(invite.id)
                        }
                    }
                    .scrollClipDisabled()
                    .padding(.top, topPull)
                    .animation(.move, value: isSingleInvite)
                }
                .isAtTopOfScroll($isAtTopOfScroll)
                .titleTravel($ui.titleTravel)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) { if vm.invites.count < 3 { infoIcon } else { eventsMenuBar } }
        .overlay(alignment: .topLeading) { if vm.invites.count >= 3 { TitleInfoIcon(ui: ui) } }
        .background { TimePickerWarmUp() }
        .task { await vm.ensureUserImageLoaded() } //Your own face for the history rows; loaded here so it's ready before the sheet opens
        .sheet(item: $ui.showInviteHistory) { eventProfile in
            InviteHistoryContainer(event: eventProfile.event, profileImage: eventProfile.image, userImage: vm.userImage)
        }
        .fullScreenCover(isPresented: $ui.showInfo) {
            infoPage
        }
        
    }
}

//1. Logic for ProfileContainer
extension InvitesContainer {
    
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        
        ToolbarItem(placement: .topBarLeading) {
            ScoopButton(style: .glass, shape: .capsule) {
                
            } label: {
                Text("Hello")
                    .font(.body(12, .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
        }
    }
    
    private func fetchDay(invite: EventProfile) -> String {
        guard let date = invite.event.proposedTimes.firstDate else { return "" }
        return FormatEvent.shortMonthDay(date)
    }
    
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

//Logic with the scroll Menu at the top
extension InvitesContainer {
    
    //The chips scroll in their own lane that ends before the toggle, so none ever slides under it
    private var eventsMenuBar: some View {
        HStack(spacing: Spacing.xs) {
            if ui.showEventsScrollMenu { actionRow }
            toggleEventsMenuButton
        }
        .padding(.top, Spacing.md)
    }

    private var actionRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.sm) {
                ForEach(vm.invites, id: \.self) { invite in
                    ScoopButton(style: .glass, shape: .capsule) {
                        withAnimation(.move) { scrollPosition.scrollTo(id: invite.id) }
                    } label: {
                    Text("\(invite.profile.name) · \(fetchDay(invite: invite))")
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .font(.body(12, .bold)) //+ your padding; each capsule hugs its label
                    }
                }
            }
            .instantPressDelivery()
        }
        .contentMargins(.leading, Spacing.gutter, for: .scrollContent)
        .contentMargins(.trailing, Spacing.lg, for: .scrollContent) //The last chip can rest clear of the fade
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .mask { chipFadeMask }
        .blurPop(visible: isAtTopOfScroll, anchor: .leading)
    }

    //Fades the chips out at the lane's end, before the toggle
    private var chipFadeMask: some View {
        HStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Spacing.lg)
        }
        .padding(.vertical, -Spacing.lg) //Taller than the row, so the chips' glass halos aren't cut above and below
    }
    
    
    private var infoIcon: some View {
        ScoopButton(shape: Circle(), size: .medium) {
            ui.showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.body(15, .medium))
                .foregroundStyle(Color.textPrimary)
        }
        .blurPop(visible: isAtTopOfScroll)
        .padding(.top, Spacing.md)
        .padding(.horizontal, Spacing.margin)
        .matchedTransitionSource(id: "info", in: infoZoom)
        .zIndex(0)
    }
    
    
    private var toggleEventsMenuButton: some View {
        ScoopButton(shape: Circle(), size: .small) {
            ui.showEventsScrollMenu.toggle()
        } label: {
            ZStack {
                if ui.showEventsScrollMenu {
                    Image(systemName: "eye.slash")
                        .font(.body(12, .bold))
                        .transition(.blurReplace)
                } else {
                    Text(vm.invites.count, format: .number)
                        .font(.body(11, .bold))
                        .transition(.blurReplace)
                }
            }
            .animation(.transition, value: ui.showEventsScrollMenu)
        }
        .padding(.trailing, ui.showEventsScrollMenu ? Spacing.gutter : Spacing.margin)
    }
    
    private var infoPage: some View {
        Text("Hello World")
            .navigationTransition(.zoom(sourceID: "info", in: infoZoom))
    }
}


//Mirrors MeetContainer's TitleInfoIcon; only the leading changes with the title's width
private struct TitleInfoIcon: View {

    let ui: InvitesUIState

    private let band: CGFloat = 44 //Geometry: the title's travel from rest to the nav bar

    var body: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(Color.textTertiary)
            .font(.body(14, .medium))
            .frame(width: 44, height: 44) //Geometry: finger-sized hit area around the 16pt glyph
            .shrinkPress {ui.showInfo = true}
            .padding(.top, 53)      //Geometry: 81 title centre − 22 half-box − 6 optical lift, from the safe-area top
            .padding(.leading, 103) //Geometry: Meet's 81 + 22, the extra ink "Invites" has over "Meet" at 32pt bold
            .offset(y: -ui.titleTravel)
            .opacity(Double(1 - min(max(ui.titleTravel, 0) / band, 1))) //only the upward half fades
    }
}


