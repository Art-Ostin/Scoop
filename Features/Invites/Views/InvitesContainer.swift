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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var chipLine: CGFloat = 12 //A chip's 12pt ModernEra line at the current Dynamic Type size
    let vm: InvitesViewModel

    //Local view state
    @State private var ui = InvitesUIState()
    @State private var isAtTopOfScroll = true
    @State private var scrollPosition = ScrollPosition()

    @State var scrollProgress: Double = 0
    
    @Namespace var calendarZoom

    private var isSingleInvite: Bool { vm.invites.count == 1 }
    private var hasEventsMenu: Bool { vm.invites.count >= 3 }
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
        .overlay(alignment: .topTrailing) {calendarButton}
        .overlay(alignment: .topLeading) { if hasEventsMenu { TitleInfoIcon(ui: ui) } }
        .background { TimePickerWarmUp() }
        .task { await vm.ensureUserImageLoaded() } //Your own face for the history rows; loaded here so it's ready before the sheet opens
        .sheet(item: $ui.showInviteHistory) { eventProfile in
            InviteHistoryContainer(event: eventProfile.event, profileImage: eventProfile.image, userImage: vm.userImage)
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
    
    //The chips scroll in their own lane that ends before the toggle, so none ever rests under it; they sprout out of the toggle and tuck back into it
    
    private var calendarButton: some View  {
        ScoopButton(shape: Circle(), size: .medium, action: { ui.showCalendarView = true }) {
            Image("CalendarIcon") //systemName: "calendar"
                .resizable()
                .frame(width: 18, height: 18)
        }
        .blurPop(visible: isAtTopOfScroll)
        .matchedTransitionSource(id: "calendar", in: calendarZoom)
        .fullScreenCover(isPresented: $ui.showCalendarView) {calendarView}
        .padding(.top, Spacing.md) //As its small icon, sits in correct position
        .padding(.horizontal, Spacing.margin)
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
        .matchedTransitionSource(id: "calendar", in: calendarZoom)
        .zIndex(0)
    }
    
    private var calendarView: some View {
        CalendarContainer(vm: vm, onRespond: { respond($0, $1) })
            .navigationTransition(.zoom(sourceID: "calendar", in: calendarZoom))
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


/*
 private var eventsMenuBar: some View {
     HStack(spacing: EventsMenuSprout.gap) {
         if ui.eventsMenuMounted { actionRow }
//            toggleEventsMenuButton
     }
     .frame(minHeight: chipLine + 14) //Geometry: a chip's scaled line + its 7pt padding pair, so the toggle centres in one height with or without the lane
     .padding(.top, Spacing.md)
     .onAppear { if !ui.showEventsScrollMenu && ui.eventsMenuMounted { shutEventsMenu() } } //A tuck whose completion never ran leaves no glass behind
 }

 
 .overlay(alignment: .trailing) { ChipFadeVeil(progress: ui.eventsMenuSprout, reduceMotion: reduceMotion) }

 //One circle that stays on its spot while the chips leave and return; its inset and its glyphs ride their progress
 private var toggleEventsMenuButton: some View {
     let sprout = ui.eventsMenuSprout
     return ScoopButton(shape: Circle(), size: EventsMenuSprout.toggle) {
         toggleEventsMenu()
     } label: {
         ZStack {
             Text(vm.invites.count, format: .number)
                 .font(.body(13, .bold))
                 .contentTransition(.numericText())
                 .animation(.transition, value: vm.invites.count) //A count that changes while tucked rolls its digits
                 .modifier(ToggleGlyphPose(progress: sprout, showsOpen: false, reduceMotion: reduceMotion))
             Image(systemName: "eye.slash")
                 .font(.body(12, .bold))
         }
     }
     .padding(.trailing, Spacing.gutter)
     .accessibilityLabel(ui.showEventsScrollMenu ? "Hide invite shortcuts" : "Show \(vm.invites.count) invite shortcuts")
 }

 .onChange(of: hasEventsMenu) { _, hasMenu in if !hasMenu { shutEventsMenu() } } //Under three invites the bar goes, so it comes back tucked, never half-open
 .modifier(ChipSprout(progress: ui.eventsMenuSprout, reduceMotion: reduceMotion))
 .modifier(ToggleGlyphPose(progress: sprout, showsOpen: true, reduceMotion: reduceMotion))
 .modifier(ToggleGlyphPose(progress: sprout, showsOpen: false, reduceMotion: reduceMotion))

 private var actionRow: some View {
     ScrollView(.horizontal) {
         HStack(spacing: Spacing.sm) {
             ForEach(vm.invites) { invite in
                 ScoopButton(style: .glass, shape: .capsule) {
                     guard ui.showEventsScrollMenu else { return } //Hit-testing runs at model values, so a chip tucking home still takes taps at its slot
                     withAnimation(.move) { scrollPosition.scrollTo(id: invite.id) }
                 } label: {
                     Text("\(invite.profile.name) · \(fetchDay(invite: invite))")
                         .padding(.vertical, 7) //Geometry: ModernEra's 12pt line + 14 = the toggle's 26pt disc at the default text size, so the chips fly level with its centre
                         .padding(.horizontal, 10)
                         .font(.body(12, .bold)) //+ your padding; each capsule hugs its label
                 }
             }
         }
         .instantPressDelivery()
         .animation(.move, value: vm.invites.map(\.id)) //An invite arriving or leaving while open reflows the lane instead of cutting
     }
     .contentMargins(.leading, Spacing.gutter, for: .scrollContent)
     .contentMargins(.trailing, Spacing.lg, for: .scrollContent) //The last chip can rest clear of the fade
     .scrollIndicators(.hidden)
     .scrollClipDisabled()
     .accessibilityHidden(!ui.showEventsScrollMenu || !isAtTopOfScroll) //Unreachable from the tap that tucks them, and while the row is popped away
     .blurPop(visible: isAtTopOfScroll, anchor: .leading)
 }

 */
