//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI
import Lottie



struct MeetContainer: View {
    
    let vm: InviteViewModel
    @State private var ui = MeetUIState()
    @State var imageSize: CGFloat = 0

    // Holds the pending send action while the morph's confirm alert is up. Hoisted here
    // so the alert can be presented full-screen above the (frame-clamped) morph card.
    @State private var pendingInvite: (() -> Void)?

    //Card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()
    
    //Logic for showing
    @State private var isAtTopOfScroll = true

    init(vm: InviteViewModel) { self.vm = vm }
    

    var body: some View {
        NavigationStack {
            meetView
                .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                .navigationTitle("Meet")
        }
        .overlay(alignment: .topTrailing) {infoButton}
        .profileMorphHost(profileMorph)
        
        .profileView(presentedID: ui.openProfile?.id) {profileView()}
        .responseCover(presentedID: ui.respondedToProfile) {RespondedToProfileView(responseType: $0)}
        
        .quickInvite(openPopupId: $ui.quickInvite, hideCard: pendingInvite != nil, style: .send.sideMargin(SendInviteContainer.screenMargin)) { id in
            timeAndPlaceView(id)
        } overlay: {
            MorphConfirmAlert(pending: $pendingInvite)
        }
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfoCover()}
    }
}

//1. Profile View Logic
extension MeetContainer {
    
    @ViewBuilder
    private func profileView() -> some View {
        if let profile = ui.openProfile {
            ProfileView(
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
            onQuickInvite: { ui.quickInvite = profile.profile.id },
            profile: profile, size: imageSize,
            imageLoader: vm.imageLoader)
            .task { await vm.loadProfileImages(profile: profile.profile) }
            .customShadow(.card, strength: 4)//Shadow works Nicely Keep!
    }
}

//3. Time And Place Popup Logic
extension MeetContainer {
    
    @ViewBuilder
    private func timeAndPlaceView(_ profileId: String) -> some View {
        if let profileEvent = fetchPendingProfileFromId(profileId) {
            InviteTimeAndPlaceView(
                vm: timeAndPlaceViewModel(profileEvent),
                sendInvite: { sendInvite(profileEvent, draft: $0) },
                requestConfirm: { pendingInvite = $0 }
            )
        }
    }

    private func fetchPendingProfileFromId(_ profileId: String) -> PendingProfile? {
        return vm.profiles.first(where: {$0.id == profileId})
    }
    
    private func timeAndPlaceViewModel(_ profileEvent: PendingProfile) -> TimeAndPlaceViewModel {
        TimeAndPlaceViewModel(inviteModel: inviteModel(profileEvent), defaults: vm.defaults)
    }
    
    private func inviteModel(_ profileEvent: PendingProfile) -> InviteModel {
        InviteModel(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
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
        guard ui.openProfile == nil else { return }
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
