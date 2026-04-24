//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI


struct InvitesContainer: View {
    
    @State var ui = InvitesUIState()
    
    @State var vm: InvitesViewModel
    @State var profileImages: [String : [UIImage]] = [:]
    @State var showTint: Bool = false
    @State var showTimePopup: Bool = false
    
    @State var hideInviteTitle: Bool = false
    
    var body: some View {
        if vm.invites.isEmpty {
            invitesPlaceholder
        } else {
            ZStack {
                invitesView
                if let profile = ui.selectedProfile { profileView(profile: profile)}
                
                if ui.quickInvite { quickInvite }
                
                if let response = ui.respondedToProfile {
                    RespondedToProfileView(response: response)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onPreferenceChange(IsTimeOpen.self) { newValue in
                showTimePopup = newValue
            }
        }
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
                    showQuickInvite: $ui.profileInvite,
                    vm: RespondViewModel(
                        image: profileImages[invite.profile.id]?.first ?? UIImage(), user: invite.profile,
                        defaults: vm.defaults,
                        sessionManager: vm.session,
                        event: invite.event
                    ),
                    ui: ui,
                    eventProfile: invite,
                    showTimePopup: showTimePopup) { profile in
                        openProfile(profile)
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
            
            TabInfoButton(showScreen: $ui.showDetails)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var invitesPlaceholder: some View {
        Text("There are no current invites")
    }
}

//ProfileView Related
extension InvitesContainer {
    
    @ViewBuilder
    private func profileView(profile: UserProfile) -> some View {
        if let eventProfile = fetchEventProfile(profile) {
            ProfileView(
                vm: ProfileViewModel(
                    defaults: vm.defaults,
                    s: vm.session,
                    profile: eventProfile.profile,
                    event: eventProfile.event,
                    imageLoader: vm.imageLoader
                ),
                profileImages: profileImages[eventProfile.profile.id] ?? [],
                selectedProfile: $ui.selectedProfile,
                dismissOffset: $ui.dismissOffset) { acceptedInvite in
                    Task {
                        await respondToProfile(respondType: .accepted, profile: profile)
                    }
                } sendNewTime: { newTime in
                    Task {
                        await respondToProfile(respondType: .newTime, profile: profile)
                    }
                } sendInvite: { eventDraft in
                    Task {
                        await respondToProfile(respondType: .newInvite, event: eventDraft, profile: profile)
                    }
                } declineInvite: { userEvent in
                    Task {
                        await respondToProfile(respondType: .decline, profile: profile)
                    }
                }
                .id(eventProfile.profile.id)
                .zIndex(1)
                .transition(.move(edge: .bottom))
        }
    }
            
    @ViewBuilder
    private var quickInvite: some View {
        if let profile = ui.profileInvite {
            InviteTimeAndPlaceView(
                vm: TimeAndPlaceViewModel(
                    defaults: vm.defaults,
                    sessionManager: vm.session,
                    profile: profile,
                    image: profileImages[profile.id]?.first ?? UIImage()
                ),
                showInvite: $ui.quickInvite,
                isNewEvent: true) { draft in
                    Task{ @MainActor in
                        await respondToProfile(respondType: .newInvite, event: draft, profile: profile)
                    }
                }
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
    
    
    
    private func respondToProfile(respondType: ProfileResponse, event: EventDraft? = nil, profile: UserProfile) async {
        //1. Set a minimum of 0.75s timer for the response view to be showing
        async let minDelay: Void = Task.sleep(for: .milliseconds(750))
        //2. Trigger the Overlay Screen
        ui.respondedToProfile = respondType
        
        try? await Task.sleep(for: .milliseconds(750))
        ui.selectedProfile = nil
        
        //3. Actually call the function in the View Model
        print("Would actually send invite Here")
        
        //4.if the minimum of 0.75s done, dismiss the screen overlay
        try? await minDelay
        ui.respondedToProfile = nil
    }
    
    /*
     
     switch respondType {
     case .accept:
         try? await respondToProfile(event: event, profile: profile, isNewTime: false)
     case .decline:
         try? await respondToProfile(profile: profile, isNewTime: false)
     case .newTime:
         try? await respondToProfile(event: event, profile: profile, isNewTime: true)
     }
     */
}

/*
 
 private func respondToProfile(draft: EventDraft, profile: UserProfile) async {
     try? await vm.sendNewInvite(draft: draft, profile: profile)
 }
 
 private func sendInvite(eventDraft: EventDraft) {
     
 }
 
 private func acceptInvite(eventDraft: UserEvent) {
     
 }
 
 private func declineProfile(userEvent: UserEvent) {
     
 }

 
 ProfileView(
     vm: ProfileViewModel(
         defaults: vm.defaults,
         s: vm.session,
         profile: eventProfile.profile,
         event: eventProfile.event,
         imageLoader: vm.imageLoader
     ),
     profileImages: profileImages[eventProfile.profile.id] ?? [],
     selectedProfile: $ui.selectedProfile,
     dismissOffset: $ui.dismissOffset,
     sendInvite: { draft in
         Task {
             await respondToProfile(respondType: .newInvite, event: draft, profile: profile)
         }
     },
     acceptInvite: { acceptInviteModel in
         Task {
             await respondToProfile(respondType: .accepted, profile: profile)
         }
     },
     declineProfile: { declineProfileId in
         Task {
             await respondToProfile(respondType: .decline, profile: profile)
         }
     }
 )
}
 
 event: EventDraft? = nil, profile: UserProfile, isNewTime: Bool) async {
 let isNewEvent = event != nil
 
 
 
 let isInvite = event != nil
 
 
 
 
 
 ui.respondedToProfile = isInvite ? .invite : .declined
 
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
 */
