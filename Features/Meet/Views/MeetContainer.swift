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
    @State private var morphInviteId: String?
    @State private var pendingInvite: (() -> Void)?

    //Card image → profile pager hero morph (see ProfileMorph.swift)
    @State private var profileMorph = ProfileMorphState()
    
    //Logic for showing
    @State private var isAtTopOfScroll = true

    init(vm: InviteViewModel) { self.vm = vm }
    

    var body: some View {
        ZStack {
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
            }
            .overlay(alignment: .topTrailing) {
                InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll)
            }

        }
        .profileMorphHost(profileMorph)
        //Both present above the root TabView: the real tab bar sits behind the
        //profile (revealed + dimmed during the zoom dismissal) and the response
        //cover physically occludes it.
        .profileOverlay(id: ui.openProfile?.id) {
            if let profile = ui.openProfile { profileView(profile: profile) }
        }
        .profileOverlay(.cover, id: ui.respondedToProfile.map { "\($0)" }) {
            if let response = ui.respondedToProfile { RespondedToProfileView(response: response) }
        }
        .quickInviteMorph(iconId: $ui.quickInvite, morphInviteId: $morphInviteId, hideCard: pendingInvite != nil, showsHideButton: true) { id in
            timeAndPlaceView(id)
        } overlay: {
            MorphConfirmAlert(pending: $pendingInvite)
        }
        .fullScreenCover(isPresented: $ui.showInfo) {MeetInfoCover()}
    }
}

//Views
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
        .colorBackground()
    }

    private var profileCardsSection: some View {
        LazyVStack(spacing: 72) {
            ForEach(vm.profiles) { profile in
                ProfileCard(
                    onTap: { image in openProfile(profile, image: image) },
                    onQuickInvite: { ui.quickInvite = profile.profile.id },
                    profile: profile, size: imageSize,
                    imageLoader: vm.imageLoader,
                    isMorphing: morphInviteId == profile.profile.id)
                    .task { await vm.loadProfileImages(profile: profile.profile) }
                    .customShadow(.card, strength: 4)//Shadow works Nicely Keep!
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
        .padding(.top, 36)
    }
            
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm: ProfileViewModel(
                profile: profile,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            profileImages: vm.profileImages[profile.id] ?? seedImages(for: profile),
            mode: .sendInvite(
                onSend: { draft in
                    Task { await respondToProfile(event: draft, profile: profile) }
                },
                onDecline: {
                    Task { await respondToProfile(profile: profile) }
                }
            ),
            onDismiss: { ui.openProfile = nil }
        )
        .id(profile.id)
        //Cross-fades in the same 0.3s transaction as the card image flight.
        .opacity(profileMorph.contentOpacity)
        //Rendered at the app root, outside this container's environment.
        .environment(profileMorph)
    }

    //If the async profile images haven't landed yet, seed the pager with the card
    //image so the morph destination exists (and is identical) on frame one.
    private func seedImages(for profile: UserProfile) -> [UIImage] {
        vm.profiles.first { $0.profile.id == profile.id }.map { [$0.image] } ?? []
    }
    
    @ViewBuilder private func timeAndPlaceView(_ profileId: String) -> some View {
        if let profileEvent = vm.profiles.first(where: {$0.id == profileId}) {
            let inviteModel = InviteModel(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                sendInvite: { inviteDraft in
                    Task {await respondToProfile(event: inviteDraft, profile: profileEvent.profile)}
                },
                requestConfirm: { pendingInvite = $0 }
            )
        }
    }
}

//Functions
extension MeetContainer {
    
    private func openProfile(_ profile: PendingProfile, image: UIImage) {
        guard ui.openProfile == nil else { return }
        profileMorph.beginOpen(id: profile.profile.id, image: image)
        ui.openProfile = profile.profile
    }

    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        let isInvite = event != nil
        //1. Set a minimum of 0.75s timer for the response view to be showing
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        ui.respondedToProfile = isInvite ? .newInvite : .decline
        
        try? await Task.sleep(for: .milliseconds(200)) //Animation is 0.18 seconds so 0.02 buffer
        //2. After 0.25 seconds either dismiss the profile, or quickInvite in background
        //(programmatic teardown behind the response cover — no flight, just reset)
        ui.openProfile = nil
        ui.quickInvite = nil
        profileMorph.reset()
        
        //3. Actually send invite or decline profile
        if let event {
            do {
                try await vm.sendInvite(event: event, profile: profile)
            } catch {
                print(error)
            }
        } else {
            try? await vm.declineProfile(profile: profile)
        }
        
        //4.if the minimum of 0.75s done, dismiss the screen
        try? await minDelay
        ui.respondedToProfile = nil
    }
    
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }
}
