//
//  DailyProfiles.swift
//  Scoop
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI
import Lottie



struct MeetContainer: View {

    let vm: MeetViewModel
    @State private var ui = MeetUIState()
    @State var imageSize: CGFloat = 0

    //Card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()

    //Logic for showing
    @State private var isAtTopOfScroll = true

    //Drives the invite's pin-to-top scroll with absolute offsets (anchor-based scrollTo
    //aims below the nav title's dynamic inset and lands short).
    @State private var feedPosition = ScrollPosition()
    //Live scroll offset. A plain class, NOT @Observable: it's written every scroll frame
    //and must never invalidate the feed's body; it's only read inside scrollToQuickInvite.
    @State private var feedOffset = FeedScrollOffset()
    //Status-bar line — where the expanded invite card pins (matches the old overlay design).
    @State private var topSafeInset: CGFloat = 0

    init(vm: MeetViewModel) { self.vm = vm }


    var body: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
            }
            .overlay(alignment: .topTrailing) {infoButton}
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topSafeInset = $0 }
        .profileMorphHost(profileMorph)
        .profileView(presentedID: ui.openProfile?.id) {profileView()}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileCover(responseType: $0)}
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfo()}
    }
}

//1. Profile View Logic
extension MeetContainer {

    @ViewBuilder
    private func profileView() -> some View {
        if let profile = ui.openProfile {
            ProfileContainer(
                vm: profileVM(profile),
                profileImages: profileImages(profile),
                mode: sendInvite(profile),
                onDismiss: { ui.openProfile = nil }
            )
            .id(profile.id)
            .opacity(profileMorph.contentOpacity)
            .environment(profileMorph)
        }
    }

    private func profileVM(_ profile: UserProfile) -> ProfileViewModel {
        ProfileViewModel(profile: profile, imageLoader: vm.imageLoader, defaults: vm.defaults)
    }

    private func profileImages(_ profile: UserProfile) -> [UIImage] {
        vm.profileImages[profile.id] ?? seedImages(for: profile)
    }

    private func sendInvite(_ profile: UserProfile) -> ProfileMode {
        return .sendInvite { draft in
            Task {await respondToProfile(event: draft, profile: profile)}
        } onDecline: {
            Task { await respondToProfile(profile: profile) }
        }
    }
}

//2. Profile Card Section Logic
extension MeetContainer {

    private var meetView: some View {
        ScrollView {
            if vm.profiles.isEmpty {
                meetPlaceholder
            } else {
                profileCardsSection
            }
        }
        .trackTopOfScroll($isAtTopOfScroll)
        //User scrolling pauses only while the close flight runs (the card must return
        //to a stationary cell); the expanded card scrolls freely with the feed.
        .scrollDisabled(ui.quickInvite != nil && !ui.quickInviteExpanded)
        .scrollPosition($feedPosition)
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
            feedOffset.y = y
        }
        .transition(.opacity)
        .id(vm.profiles.count)
        .scrollIndicators(.hidden)
    }

    private var profileCardsSection: some View {
        LazyVStack(spacing: 64) {
            ForEach(vm.profiles) { profile in
                profileCard(profile)
            }
        }
        .padding(.top, 36)
        //Extra tail room while an invite is up, so any card — the last included — can
        //reach the top of the viewport when it expands. Retracts with the close spring.
        .padding(.bottom, ui.quickInviteTailRoom ? 400 : 60)
    }

    private func profileCard(_ profile: PendingProfile) -> some View {
        ProfileCard(
            onTap: { image in openProfile(profile, image: image) },
            onQuickInvite: { image in openQuickInvite(profile, image: image) },
            profile: profile,
            size: imageSize,
            imageLoader: vm.imageLoader,
            quickInvite: quickInviteState(profile)
        )
        .task { await vm.loadProfileImages(profile: profile.profile) }
    }
}

//3. Quick Invite Logic
extension MeetContainer {

    //The invite is an expanded state of the profile card, morphing inside its feed cell
    //(see SendInviteCard); this builds the config that puts the card in that state.
    private func quickInviteState(_ profile: PendingProfile) -> ProfileCard.QuickInvite? {
        guard ui.quickInvite?.id == profile.id, let image = ui.quickInviteImage else { return nil }
        return ProfileCard.QuickInvite(
            vm: TimeAndPlaceViewModel(inviteModel: inviteModel(profile), defaults: vm.defaults),
            image: image,
            images: vm.profileImages[profile.profile.id] ?? [image],
            expanded: $ui.quickInviteExpanded,
            onExpand: { scrollToQuickInvite(profile) },
            onHide: { closeQuickInvite() },
            onSend: { sendInvite(profile, draft: $0) }
        )
    }

    //Pins the expanding card to the status-bar line, where the old overlay design put it.
    //Absolute offset: the card's on-screen top is already tracked by the profile morph, so
    //the target is exact regardless of the nav title's large/inline inset state. Called
    //inside the open transaction, so the scroll rides the same spring as the expansion.
    private func scrollToQuickInvite(_ profile: PendingProfile) {
        guard let cardTop = profileMorph.sourceRect(id: profile.profile.id)?.minY else { return }
        feedPosition.scrollTo(point: CGPoint(x: 0, y: feedOffset.y + cardTop - topSafeInset))
    }

    private func openQuickInvite(_ profile: PendingProfile, image: UIImage) {
        if ui.quickInvite?.id == profile.id { //Reopen mid-close: retarget the spring
            withAnimation(SendInviteCard.openFlight) {
                ui.quickInviteExpanded = true
                ui.quickInviteTailRoom = true
                scrollToQuickInvite(profile)
            }
            return
        }
        guard ui.openProfile == nil else { return }
        if ui.quickInvite != nil { //Another card's invite is up: dismiss it, then open this one
            switchQuickInvite(to: profile, image: image)
            return
        }
        ui.quickInviteImage = image
        ui.quickInvite = profile
        ui.quickInviteTailRoom = true //Before the flight, so the scroll-to-top isn't clamped short
    }

    //Serial on purpose: the new card's pin math must never run against a feed whose
    //layout is still shifting from the old card's collapse.
    private func switchQuickInvite(to profile: PendingProfile, image: UIImage) {
        if ui.quickInviteExpanded {
            closeQuickInvite { openQuickInvite(profile, image: image) }
        } else { //Close tail already running: cut it short (its completion no-ops on the id guard)
            ui.quickInvite = nil
            ui.quickInviteImage = nil
            openQuickInvite(profile, image: image)
        }
    }

    //Reverse flight; unmounts only once the spring FULLY settles (`.removed` —
    //the default `.logicallyComplete` fires while the spring tail is still moving,
    //so unmounting there cuts off the last points of travel: an end-of-close snap).
    //Skipped if reopened mid-close or superseded by a switch to another card.
    private func closeQuickInvite(then openNext: (() -> Void)? = nil) {
        guard ui.quickInviteExpanded else { return }
        let closing = ui.quickInvite
        withAnimation(SendInviteCard.closeFlight, completionCriteria: .removed) {
            ui.quickInviteExpanded = false
            ui.quickInviteTailRoom = false
        } completion: {
            guard !ui.quickInviteExpanded, ui.quickInvite?.id == closing?.id else { return }
            ui.quickInvite = nil
            ui.quickInviteImage = nil
            openNext?()
        }
    }

    private func inviteModel(_ profileEvent: PendingProfile) -> InviteContext {
        InviteContext(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
    }

    private func sendInvite(_ profileEvent: PendingProfile, draft: EventFieldsDraft) {
        Task {await respondToProfile(event: draft, profile: profileEvent.profile)}
    }
}

//Key Functions
extension MeetContainer {

    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.profiles.first { $0.profile.id == profile.id }.map { [$0.image] } ?? []
    }

    //Quick-invite guard keys on `expanded`, not mount state: during the close
    //tail the card lingers (`.removed` unmount) but must not block profile taps.
    private func openProfile(_ profile: PendingProfile, image: UIImage) {
        guard ui.openProfile == nil, !ui.quickInviteExpanded else { return }
        profileMorph.beginOpen(id: profile.profile.id, image: image)
        ui.openProfile = profile.profile
    }

    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        //Step 1: Min time for whole process 0.85 seconds
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))

        //Step 2: Show respond fullScreencover. Animation to open takes 0.2
        ui.respondedToProfile = event == nil ? .decline : .newInvite

        //Step 3: Step 3: After 0.2s, dismiss the profile and invite popups beneath the respond cover
        try? await Task.sleep(for: .milliseconds(200))
        hideProfileAndInviteInBackground()

        //Step 4: Actually send invite or decline profile
        await submitResponse(event: event, profile: profile)

        //Step 5: Once minimum of 0.85 seconds done, dismiss the screen
        try? await minDelay
        ui.respondedToProfile = nil
    }

    private func hideProfileAndInviteInBackground() {
        ui.openProfile = nil
        ui.quickInvite = nil
        ui.quickInviteImage = nil
        ui.quickInviteExpanded = false
        ui.quickInviteTailRoom = false
        profileMorph.reset()
    }

    private func submitResponse(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        if let event {
            try? await vm.sendInvite(event: event, profile: profile)
        } else {
            try? await vm.declineProfile(profile: profile)
        }
    }

}

//Other Views
extension MeetContainer {
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }

    private var infoButton: some View {
        InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll)
    }
}

//Deliberately NOT @Observable: updated every scroll frame, and observation would
//re-evaluate the whole feed per frame. Held in @State only for a stable identity.
private final class FeedScrollOffset {
    var y: CGFloat = 0
}
