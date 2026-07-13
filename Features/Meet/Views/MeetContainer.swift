//
//  DailyProfiles.swift
//  Scoop
//
//  Created by Art Ostin on 08/08/2025.
//
import SwiftUI


struct MeetContainer: View {
    
    //Inject Dependencies
    let vm: MeetViewModel

    //Local view state
    @State private var ui = MeetUIState()
    @State private var profileMorph = ProfileMorphState()
    @State private var isAtTopOfScroll = true

    
    var body: some View {
        NavigationStack {
            TabScrollView(type: .meet, showEmptyView: vm.profiles.isEmpty) {
                profileList
            }
            .isAtTopOfScroll($isAtTopOfScroll)
        }
        .overlay(alignment: .topTrailing) {infoButton}
        .profileMorphHost(profileMorph)
        
        
        
        
        
        //Different sub views of meetContainer
        .profileView(presentedID: ui.openProfile?.id, morph: profileMorph) {profileView()}
        .inviteView(presentedID: ui.quickInvite?.id) {inviteOverlay()}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileCover(responseType: $0)}
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfo()}
    }
}

//1. Profile View Logic
extension MeetContainer {
    
    private var profileList: some View {
        LazyVStack(spacing: Spacing.xxxl) {
            ForEach(vm.profiles) { profile in
                profileCard(profile)
            }
        }
    }
        
    @ViewBuilder
    private func profileView() -> some View {
        if let profile = ui.openProfile {
            ProfileContainer(
                vm: ProfileViewModel(profile: profile, imageLoader: vm.imageLoader, defaults: vm.defaults),
                profileImages: vm.profileImages[profile.id] ?? seedImages(for: profile),
                mode: sendInvite(profile),
                onDismiss: { ui.openProfile = nil }
            )
        }
    }
    
    private func profileCard(_ profile: PendingProfile)-> some View {
        ProfileCard(
            profile: profile,
            quickInviteHidden: ui.quickInvite?.id == profile.id,
            onTap: {image in openProfile(profile, image: image)},
            onQuickInvite: {image in openQuickInvite(profile, image: image)}
        )
        .task { await vm.loadProfileImages(profile: profile.profile) }
        .shadow(.image)
    }

    private var infoButton: some View {
        InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll && !ui.quickInviteExpanded)
    }
}

//3. Quick Invite Logic
extension MeetContainer {

    //Rendered in the root overlay slot (above the TabView). The backdrop stands in for
    //the old meet-chrome fade AND the tab-bar hide: opaque while the card is open, it
    //rides the open/close flights via `expanded` and the dismiss drag via progress, so
    //the live bar and the meet list fade gradually — no native visibility flips.
    @ViewBuilder
    private func inviteOverlay() -> some View {
        if let invite = ui.quickInvite, let image = ui.quickInviteImage {
            ZStack {
                Color.appCanvas.ignoresSafeArea()
                    .opacity(ui.quickInviteExpanded ? 1 - ui.quickInviteDismissProgress : 0)
                    .allowsHitTesting(ui.quickInviteExpanded)
                timeAndPlaceView(invite, image)
            }
        }
    }

    @ViewBuilder
    private func timeAndPlaceView(_ pendingProfile: PendingProfile, _ image: UIImage) -> some View {
        InviteTimeAndPlaceView(
            vm: TimeAndPlaceViewModel(inviteModel: inviteModel(pendingProfile), defaults: vm.defaults),
            image: image,
            images: vm.profileImages[pendingProfile.profile.id] ?? [image],
            details: profileDetails(pendingProfile.profile),
            expanded: $ui.quickInviteExpanded,
            sourceFrame: ui.quickInviteSource,
            onDismissProgress: {ui.quickInviteDismissProgress = $0},
            hideInvite: {closeQuickInvite()},
            sendInvite: {sendInvite(pendingProfile, draft: $0)}
        )
    }
    
    private func openQuickInvite(_ profile: PendingProfile, image: UIImage) {
        if ui.quickInvite?.id == profile.id { //Reopen mid-close: retarget the spring
            withAnimation(SendInviteCard.openFlight) { ui.quickInviteExpanded = true }
            return
        }
        guard ui.quickInvite == nil, ui.openProfile == nil else { return }
        ui.quickInviteDismissProgress = 0
        ui.quickInviteSource = profileMorph.sourceRect(id: profile.profile.id) ?? .zero
        ui.quickInviteImage = image
        ui.quickInvite = profile
    }

    //Reverse flight; unmounts only once the spring FULLY settles (`.removed` —
    //the default `.logicallyComplete` fires while the spring tail is still moving,
    //so unmounting there cuts off the last points of travel: an end-of-close snap).
    //Skipped if reopened mid-close.
    private func closeQuickInvite() {
        guard ui.quickInviteExpanded else { return }
        withAnimation(SendInviteCard.closeFlight, completionCriteria: .removed) {
            ui.quickInviteExpanded = false
        } completion: {
            guard !ui.quickInviteExpanded else { return }
            ui.quickInvite = nil
            ui.quickInviteImage = nil
            ui.quickInviteSource = .zero
        }
    }
    
    //Must match ProfileCard's info line exactly — the flight chrome fades it out in place.
    private func profileDetails(_ p: UserProfile) -> String {
        "\(p.year) | \(p.degree) | \(p.hometown)"
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
    
    
    
    private func sendInvite(_ profile: UserProfile) -> ProfileMode {
        return .sendInvite { draft in
            Task {await respondToProfile(event: draft, profile: profile)}
        } onDecline: {
            Task { await respondToProfile(profile: profile) }
        }
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
