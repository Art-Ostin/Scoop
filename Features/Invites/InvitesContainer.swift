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
    
    var body: some View {
        if vm.invites.isEmpty {
            invitesPlaceholder
        } else {
            
            ZStack {
                invitesView
                
                if let profile = ui.selectedProfile {
                    if let eventProfile = fetchEventProfile(profile) {
                        profileView(eventProfile: eventProfile)
                    }
                }
            }
        }
    }
}

extension InvitesContainer {
    
    private func fetchEventProfile(_ profile: UserProfile) -> EventProfile? {
        vm.invites.first { $0.profile.id == profile.id }
    }

    private var invitesView: some View {
        VStack(spacing: 24) {
            titleAndTab
            
            ForEach(vm.invites, id: \.self) { invite in
                InviteCard(
                    vm: RespondViewModel(
                        image: profileImages[invite.profile.id]?.first ?? UIImage(),
                        defaults: vm.defaults,
                        sessionManager: vm.session,
                        respondDraft: .init(event: invite.event, userId: vm.userId)
                    ),ui: ui,
                    eventProfile: invite) { profile in
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
    private func profileView(eventProfile: EventProfile) -> some View {
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
                // sendInvite
            },
            acceptInvite: { acceptInviteModel in
                // acceptInvite
            },
            declineProfile: { declineProfileId in
                // declineProfile
            }
        )
        .id(eventProfile.profile.id)
        .zIndex(1)
        .transition(.move(edge: .bottom))
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
    
    private func sendInvite(eventDraft: EventDraft) {
        
    }
    
    private func acceptInvite(eventDraft: UserEvent) {
        
    }
    
    private func declineProfile(userEvent: UserEvent) {
        
    }
}


/*
 
 
 
 
 InviteCard(
     timeAndPlaceVM: TimeAndPlaceViewModel(
         defaults: vm.d,
         sessionManager: vm.s,
         profile: invite.profile
     ),
     vm: vm, ui: ui, eventProfile: invite) {profile in
         openProfile(profile)
     }

 */
