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
            ForEach(vm.invites, id: \.self) { invite in
                inviteCard(invite: invite)
                    .task { await vm.ensureImagesLoaded(for: invite.profile) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
    }
}

extension InvitesView {
    
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
