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

    // Holds the pending send action while the morph's confirm alert is up. Hoisted here
    // so the alert can be presented full-screen above the (frame-clamped) morph card.
    @State private var pendingInvite: (() -> Void)?

    //Card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()
    
    //Logic for showing
    @State private var isAtTopOfScroll = true

    init(vm: MeetViewModel) { self.vm = vm }
    

    var body: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
            }
            //Meet chrome (info button included) fades with the flight and goes
            //inert while the invite card is open.
            .overlay(alignment: .topTrailing) {infoButton}
            .opacity(ui.quickInviteExpanded ? 0 : 1)
            .allowsHitTesting(!ui.quickInviteExpanded)

            if let invite = ui.quickInvite, let image = ui.quickInviteImage {
                timeAndPlaceView(invite, image)
            }
        }
        .profileMorphHost(profileMorph)
        .profileView(presentedID: ui.openProfile?.id) {profileView()}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileCover(responseType: $0)}
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfo()}
        //Driven by the animated flight value (not mount state), so the system bar
        //animates out/in with the card and returns the moment the close starts.
        .hideTabBar(hideBar: ui.quickInviteExpanded)
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
        .scrollDisabled(ui.quickInvite != nil) //The flight's source frame must not move
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
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
        .padding(.top, 36)
    }
    
    private func profileCard(_ profile: PendingProfile)-> some View {
        ProfileCard(
            onTap: { image in openProfile(profile, image: image) },
            onQuickInvite: { image in openQuickInvite(profile, image: image) },
            profile: profile,
            size: imageSize,
            imageLoader: vm.imageLoader,
            quickInviteHidden: ui.quickInvite?.id == profile.id
        )
        .task { await vm.loadProfileImages(profile: profile.profile) }
        .customShadow(.card, strength: 4)//Shadow works Nicely Keep!
    }
}

//3. Quick Invite Logic
extension MeetContainer {

    @ViewBuilder
    private func timeAndPlaceView(_ pendingProfile: PendingProfile, _ image: UIImage) -> some View {
        InviteTimeAndPlaceView(
            vm: TimeAndPlaceViewModel(inviteModel: inviteModel(pendingProfile), defaults: vm.defaults),
            image: image,
            images: vm.profileImages[pendingProfile.profile.id] ?? [image],
            details: profileDetails(pendingProfile.profile),
            expanded: $ui.quickInviteExpanded,
            sourceFrame: ui.quickInviteSource,
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

//Other Views
extension MeetContainer {
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }

    //Hides via the button's own .scoopPop show/hide (glass won't alpha-fade under
    //ancestor opacity), driven by the animated flight value so it pops back in
    //the moment the close starts.
    private var infoButton: some View {
        InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll && !ui.quickInviteExpanded)
    }
}

