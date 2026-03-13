//
//  DailyProfiles.swift
//  ScoopTest
//
//  Created by Art Ostin on 08/08/2025.
//

import SwiftUI
import Lottie



struct MeetContainer: View {
    let vm: MeetViewModel
    @State private var ui = MeetUIState()
    @State var imageSize: CGFloat = 0
    @State var profileImages: [String : [UIImage]] = [:]
    @State var dismissOffset: CGFloat? = nil //Fixes bug by controlling dismiss Offset here
    
    init(vm: MeetViewModel) { self.vm = vm }
    
    var body: some View {
        ZStack {
            meetView
            
            if let profileRec = ui.openProfile {
                profileView(profile: profileRec)
            }
            
            if let quickInviteProfile = ui.quickInvite {
                quickInviteView(profile: quickInviteProfile)
            }
            
            if let profileResponse = ui.showSentInvite {
                RespondToProfileView(response: profileResponse)
            }
        }
        .transition(.opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $ui.showPendingInvites) {PastInviteView(vm: vm, ui: ui)}
        .measure(key: ImageSizeKey.self) { $0.size.width }
        .onPreferenceChange(ImageSizeKey.self) {screenSize in
            imageSize = screenSize - (16 * 2)
        }
    }
}

extension MeetContainer {
    
    private var meetView: some View {
        CustomTabPage(page: .Meet,TabAction: $ui.showInfo) {
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
            ProfileCard(openProfile: $ui.openProfile, quickInvite: $ui.quickInvite, profile: profile, size: imageSize)
                .contentShape(Rectangle())
                .onTapGesture {openProfile(profile)}
                .task { await loadProfileImages(profile.profile) }
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
            vm: ProfileViewModel(defaults: vm.defaults, sessionManager: vm.s, profile: profile, imageLoader: vm.imageLoader), meetVM: vm,
            profileImages: profileImages[profile.id] ?? [],
            selectedProfile: $ui.openProfile,
            dismissOffset: $dismissOffset,
            showRespondToProfile: $ui.showSentInvite) {
                sendInvite(event: )
            }
        .id(profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
    }
        
    private func quickInviteView(profile: UserProfile) ->  some View {
        SelectTimeAndPlace(defaults: vm.defaults, sessionManager: vm.s, profile: profile, onDismiss: { ui.quickInvite = nil}) { event in
            Task{ @MainActor in
                await sendInvite(event: event, profile: profile)
            }
        }
    }
    
    private func sendInvite(event: EventDraft, profile: UserProfile) async {
        ui.showSentInvite = .invite
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        try? await Task.sleep(for: .milliseconds(750))
        ui.quickInvite = nil
        try? await vm.sendInvite(event: event, profile: profile)
        try? await minDelay
        ui.showSentInvite = nil
    }
}
