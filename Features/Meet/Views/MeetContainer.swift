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

            //Stays mounted while the quick invite is up: the flight needs the
            //source card's live frame and the list's scroll position preserved.
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
            }
            .opacity(ui.quickInviteExpanded ? 0 : 1)
            .allowsHitTesting(!ui.quickInviteExpanded)

            if let invite = ui.quickInvite, let image = ui.quickInviteImage {
                timeAndPlaceView(invite, image)
            }
        }
        .overlay(alignment: .topTrailing) {infoButton}
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
            expanded: $ui.quickInviteExpanded,
            sourceFrame: ui.quickInviteSource,
            hideInvite: {closeQuickInvite()},
            sendInvite: {sendInvite(pendingProfile, draft: $0)}
        )
    }

    //Mounts the card collapsed, pixel-exact over the tapped card's image;
    //SendInviteCard starts the open flight itself once its layout is measured.
    private func openQuickInvite(_ profile: PendingProfile, image: UIImage) {
        if ui.quickInvite?.id == profile.id { //Reopen mid-close: retarget the spring
            withAnimation(SendInviteCard.flight) { ui.quickInviteExpanded = true }
            return
        }
        guard ui.quickInvite == nil, ui.openProfile == nil else { return }
        ui.quickInviteSource = profileMorph.sourceRect(id: profile.profile.id) ?? .zero
        ui.quickInviteImage = image
        ui.quickInvite = profile
    }

    //Reverse flight; unmounts only once the spring settles (skipped if reopened mid-close).
    private func closeQuickInvite() {
        guard ui.quickInviteExpanded else { return }
        withAnimation(SendInviteCard.flight) {
            ui.quickInviteExpanded = false
        } completion: {
            guard !ui.quickInviteExpanded else { return }
            ui.quickInvite = nil
            ui.quickInviteImage = nil
            ui.quickInviteSource = .zero
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
    
    private func openProfile(_ profile: PendingProfile, image: UIImage) {
        guard ui.openProfile == nil, ui.quickInvite == nil else { return }
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

    private var infoButton: some View {
        InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll)
    }
}

