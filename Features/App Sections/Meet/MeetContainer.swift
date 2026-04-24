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
    @State var profileImages: [String : [UIImage]] = [:]
    @State var dismissOffset: CGFloat? = nil //Fixes bug by controlling dismiss Offset here
    
    init(vm: InviteViewModel) { self.vm = vm }
    
    var body: some View {
        ZStack {
            meetView
            
            if let profileRec = ui.openProfile {
                profileView(profile: profileRec)
            }
            
            if ui.quickInvite {
                quickInviteView
            }
            
            if let response = ui.respondedToProfile {
                RespondedToProfileView(response: response)
            }
        }
        .transition(.opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) {screenSize in
            imageSize = screenSize - (16 * 2)
        }
    }
}

extension MeetContainer {
    
    private var meetView: some View {
        CustomTabPage(page: .meet ,tabAction: $ui.showInfo) {
            if vm.profiles.isEmpty {
                meetPlaceholder
            } else {
                profileCardsSection
            }
        }
        .id(vm.profiles.count)
    }
    
    private var meetPlaceholder: some View {
        VStack {
            Text("Hello World")
        }
    }
    
    private var profileCardsSection: some View {
        ForEach(vm.profiles) { profile in
            ProfileCard(openProfile: $ui.openProfile, profileInvite: $ui.profileInvite, profile: profile, size: imageSize)
                .contentShape(Rectangle())
                .onTapGesture {openProfile(profile)}
                .task { await loadProfileImages(profile.profile) }
                .customSubtleShadow(strength: 4)//Shadow works Nicely Keep!
        }
    }
    
    private func openProfile(_ profile: PendingProfile) {
        if ui.openProfile == nil {
            dismissOffset = nil
            ui.openProfile = profile.profile
        }
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
            
    private func profileView(profile: UserProfile) -> some View {
        ProfileView(
            vm: ProfileViewModel(
                defaults: vm.defaults,
                s: vm.s,
                profile: profile,
                imageLoader: vm.imageLoader
            ),
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.openProfile,
            dismissOffset: $dismissOffset,
            sendInvite: { draft in
                Task { await respondToProfile(event: draft, profile: profile) }
            }, declineProfile: {_ in
                Task { await respondToProfile(profile: profile) }
            }
        )
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
    
    @ViewBuilder
    private var quickInviteView: some View {
        if let profile = ui.profileInvite {
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    defaults: vm.defaults,
                    sessionManager: vm.s,
                    profile: profile,
                    image: profileImages[profile.id]?.first ?? UIImage()
                ),
                showInvite: $ui.quickInvite) { draft in
                    Task{ @MainActor in
                        await respondToProfile(event: draft, profile: profile)
                    }
                }
        }
    }
}

extension MeetContainer {
    
    private func respondToProfile(event: EventDraft? = nil, profile: UserProfile) async {
        let isInvite = event != nil
        //1. Set a minimum of 0.75s timer for the response view to be showing
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        ui.respondedToProfile = isInvite ? .newInvite : .decline
        
        //2. After 0.25 seconds either dismiss the profile, or quickInvite in background
        ui.openProfile = nil
        ui.quickInvite = false
        
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
}
