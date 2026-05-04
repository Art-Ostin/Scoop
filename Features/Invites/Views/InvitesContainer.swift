//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI


struct InvitesContainer: View {
    
    @Environment(\.tabSelection) var selectedTab
    
    @State var ui = InvitesUIState()
    
    @State var vm: InvitesViewModel
    @State var profileImages: [String : [UIImage]] = [:]
    @State var showTint: Bool = false
    @State var showTimePopup: Bool = false
    @State var hideInviteTitle: Bool = false
    
    @State var showConfirmAccept: String? = nil
    @State var showConfirmNewTime: String? = nil
    @State var showConfirmNewInvite: String? = nil
    
    var isPopup: Bool {
        showConfirmAccept != nil || showConfirmNewTime != nil || showConfirmNewInvite != nil
    }

    var hideTab: Bool {
        isPopup || ui.selectedProfile != nil || ui.showQuickInvite != nil || ui.respondedToProfile != nil
    }

    var body: some View {
        ZStack {
            
            if vm.invites.isEmpty {
                InvitesPlaceholder()
            } else {
                invitesView
                
                if let profile = ui.selectedProfile { profileView(profile: profile)}
                
                if let profileId = ui.showQuickInvite { quickInvite(profileId) }
            }
            
            if let response = ui.respondedToProfile { RespondedToProfileView(response: response)}
            
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .customAlert(item: $showConfirmNewTime, title: "New Times Proposed", cancelTitle: "Cancel", okTitle: "I Understand", message: "If they accept one of your proposed times & you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
            Task {try?  await respondToProfile(respondType: .newTime, profileId: profileId)}
        }
        .customAlert(item: $showConfirmAccept, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on at. If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
            Task { try? await respondToProfile(respondType: .accepted, profileId: profileId)}
        }
        .customAlert(item: $showConfirmNewInvite, title: "Event Commitment", cancelTitle: "Cancel", okTitle: "I Understand", message: "You are committing to meet on  at. If you don't show, you'll be blocked from Scoop", showTwoButtons: true, isConfirmInvite: true) { profileId in
            Task { try? await respondToProfile(respondType: .newInvite, profileId: profileId)}
        }
        .onPreferenceChange(IsTimeOpen.self) { newValue in
            showTimePopup = newValue
        }
        .animation(.easeInOut(duration: 0.25), value: showTimePopup)
        .hideTabBar(hideBar: hideTab)
    }
}

extension InvitesContainer {

    private func fetchEventProfile(_ profile: UserProfile) -> EventProfile? {
        vm.invites.first { $0.profile.id == profile.id }
    }

    private var invitesView: some View {
        VStack(spacing: 20) {
            titleAndTab
                .opacity(showTimePopup ? (hideInviteTitle ? 0.03 : 0.2) : 1)
            
            ForEach(vm.invites, id: \.self) { invite in
                InviteCard(
                    vm: vm.respondVM(for: invite, image: invite.image ?? UIImage()),
                    ui: ui,
                    eventProfile: invite,
                    openProfile: { openProfile($0)}) { userEvent in
                        Task {
                            try await respondToProfile(respondType: .decline, profileId: invite.profile.id)
                        }
                    }
                    .task { await loadProfileImages(invite.profile) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .background(Color.background)
        .onPreferenceChange(QuickInviteTime.self) { newValue in
                showTint = newValue
        }
        .onPreferenceChange(HideInvitePreferenceKey.self) { newValue in
            hideInviteTitle = newValue
        }
        .animation(.easeInOut(duration: 0.15), value: showTimePopup)
        .animation(.easeInOut(duration: 0.15), value: hideInviteTitle)
    }
    
    private var titleAndTab: some View {
        ZStack(alignment: .top) {
            Text("Invites")
                .font(.custom("SFProRounded-Bold", size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                .padding(.leading, -4)
            
            TabInfoButton(showScreen: $ui.showDetails)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
//ProfileView Related
extension InvitesContainer {
    
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = fetchEventProfile(profile), let respondVM = vm.respondVMs[eventProfile.profile.id] {
            return ProfileView(
                vm: ProfileViewModel(
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader, defaults: vm.defaults
                ),
                profileImages: profileImages[eventProfile.profile.id] ?? [],
                selectedProfile: $ui.selectedProfile,
                dismissOffset: $ui.dismissOffset,
                mode: .respondToInvite(respondVM: respondVM) { respondType in
                    Task {
                        try? await respondToProfile(respondType: respondType, profileId: eventProfile.profile.id)
                    }
                }
            )
            .id(eventProfile.profile.id)
            .zIndex(1)
            .transition(.move(edge: .bottom))
        }
    }
    
    @ViewBuilder
    private func timeAndPlaceView(_ id: String) -> some View {
        //1. First fetch the correctProfile, as view is triggered by passing in ID
        if let eventProfile = vm.invites.first(where: { $0.id == id }), let image = eventProfile.image {
            //2. Construct the TimeAndPlaceView
            let inviteModel = InviteModel(profileId: eventProfile.profile.id, name: eventProfile.profile.name, image: image)
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(inviteModel: inviteModel, defaults: vm.defaults),
                showInvite: $ui.showQuickInvite,
                sendInvite: { draft in
                    Task { try? await respondToProfile(respondType: .newInvite, profileId: inviteModel.profileId)}
                }
            )
        }
    }
        
    private func openProfile(_ profile: UserProfile) {
        if ui.selectedProfile == nil {
            ui.dismissOffset = nil
            ui.selectedProfile = profile
        }
    }
    
    private func loadProfileImages(_ profile: UserProfile) async {
        let loadedImages = await vm.loadImages(profile: profile)
        profileImages[profile.id] = loadedImages
    }
    
}
