//
//  InviteResponseLogic.swift
//  Scoop
//
//  Created by Art Ostin on 27/04/2026.
//

import SwiftUI

struct InvitesView: View {
    
    @Bindable var ui: InvitesUIState
    @Bindable var vm: InvitesViewModel
    let onDecline: (String) -> ()
    
    var body: some View {
        VStack(spacing: 20) {
            titleAndTab
                .opacity(ui.showTimePopup ? (ui.hideInviteTitle ? 0.03 : 0.2) : 1)
            
            ForEach(vm.invites, id: \.self) { invite in
                inviteCard(invite: invite)
                    .task { await vm.ensureImagesLoaded(for: invite.profile) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .background(Color.appCanvas)
        .onPreferenceChange(HideInvitePreferenceKey.self) { newValue in
            ui.hideInviteTitle = newValue
        }
        .animation(.easeInOut(duration: 0.15), value: ui.hideInviteTitle)
    }
}

extension InvitesView {
    
    private var titleAndTab: some View {
        ZStack(alignment: .top) {
            Text("Invites")
                .font(.title())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                .padding(.leading, -4)
            
            TabInfoButton(showScreen: $ui.showDetails)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private func inviteCard(invite: EventProfile) -> some View {
        InviteCard(
            vm: vm.respondVM(for: invite),
            ui: ui,
            eventProfile: invite,
            openProfile: { openProfile($0) }) { inviteId in
                onDecline(inviteId)
            }
    }
    
    private func openProfile(_ profile: UserProfile) {
        if ui.selectedProfile == nil {
            ui.selectedProfile = profile
        }
    }
}

    
    
