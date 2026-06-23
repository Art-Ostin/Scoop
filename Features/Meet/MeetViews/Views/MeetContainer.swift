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
                .scoopNavigationBarFonts()
        }
        .overlay(alignment: .topTrailing) {
            InfoButton(showScreen: $ui.showInfo, isAtTopOfScroll: isAtTopOfScroll)
        }
        .profileMorphHost(profileMorph)
        .profileView(presentedID: ui.openProfile?.id) {
            if let profile = ui.openProfile { profileView(profile: profile) }
        }
        .responseCover(presentedID: ui.respondedToProfile) { response in
            RespondedToProfileView(responseType: response)
        }
        //The send card now owns its Hide button and fades itself behind the confirm alert,
        //so the morph draws neither (showsHideButton defaults false) and needs no overlay.
        .quickInvite(openPopupId: $ui.quickInvite, style: QuickInviteMorphStyle(contentOwnsBackground: true).sideMargin(SendInviteContainer.screenMargin)) { id in
            timeAndPlaceView(id)
        } overlay: {
            EmptyView()
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
                    imageLoader: vm.imageLoader)
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
                onHide: { ui.quickInvite = nil }
            )
        }
    }
}


extension MeetContainer {
    
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
    
    
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }
}
