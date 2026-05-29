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
    init(vm: InviteViewModel) { self.vm = vm }
    
    var body: some View {
        ZStack {
            NavigationStack {
                meetView
                    .getImageSize(imageSize: $imageSize, horizontalPadding: 16)
                    .navigationTitle("Meet")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Image(systemName: "xmark")
                        }
                    }
            }

            if let profileRec = ui.openProfile { profileView(profile: profileRec)}

            if let profileId = ui.quickInvite { timeAndPlaceView(profileId)}

            if let response = ui.respondedToProfile {RespondedToProfileView(response: response)}
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
        .transition(.opacity)
        .id(vm.profiles.count)
        .scrollIndicators(.hidden)
        .background(Color.appCanvas)
    }

    private var profileCardsSection: some View {
        LazyVStack(spacing: 60) {
            ForEach(vm.profiles) { profile in
                ProfileCard(
                    onTap: { openProfile(profile) },
                    onQuickInvite: { ui.quickInvite = profile.profile.id },
                    profile: profile, size: imageSize,
                    imageLoader: vm.imageLoader
                )
                    .task { await vm.loadProfileImages(profile: profile.profile) }
                    .customSubtleShadow(strength: 4)//Shadow works Nicely Keep!
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 48)
        .padding(.bottom, 60)
    }
            
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm: ProfileViewModel(
                profile: profile,
                imageLoader: vm.imageLoader, defaults: vm.defaults
            ),
            profileImages: vm.profileImages[profile.id] ?? [],
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
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    @ViewBuilder private func timeAndPlaceView(_ profileId: String) -> some View {
        if let profileEvent = vm.profiles.first(where: {$0.id == profileId}) {
            let inviteModel = InviteModel(profileId: profileEvent.id, name: profileEvent.profile.name, image: profileEvent.image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                showInvite: $ui.quickInvite) { inviteDraft in
                    Task {await respondToProfile(event: inviteDraft, profile: profileEvent.profile)}
                }
        }
    }
}

//Functions
extension MeetContainer {
    
    private func openProfile(_ profile: PendingProfile) {
        if ui.openProfile == nil {
            ui.openProfile = profile.profile
        }
    }

    private func respondToProfile(event: EventFieldsDraft? = nil, profile: UserProfile) async {
        let isInvite = event != nil
        //1. Set a minimum of 0.75s timer for the response view to be showing
        async let minDelay: Void = Task.sleep(for: .milliseconds(850))
        ui.respondedToProfile = isInvite ? .newInvite : .decline
        
        try? await Task.sleep(for: .milliseconds(200)) //Animation is 0.18 seconds so 0.02 buffer
        //2. After 0.25 seconds either dismiss the profile, or quickInvite in background
        ui.openProfile = nil
        ui.quickInvite = nil
        
        //3. Actually send invite or decline profile
        if let event {
            try? await vm.sendInvite(event: event, profile: profile)
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
