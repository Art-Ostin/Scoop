//
//  InviteResponseLogic.swift
//  Scoop
//
//  Created by Art Ostin on 27/04/2026.
//

import SwiftUI

struct InvitesView: View {
    
    let imageSize: CGFloat
    
    @Bindable var ui: InvitesUIState
    @Bindable var vm: InvitesViewModel
    let onDecline: (String) -> ()
    
    
    var body: some View {
        VStack(spacing: 96) {
            ForEach(vm.invites, id: \.self) { invite in
                inviteCard(invite)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
    }
}

extension InvitesView {
    
    private func inviteCard(_ invite: EventProfile) -> some View {
        InviteCard(
            selectedProfile: $ui.selectedProfile,
            draft: vm.draftBinding(for: invite),
            eventProfile: invite,
            imageSize: imageSize,
            onRespond: {ui.showRespondPopup = invite.event.id}
        )
        .customShadow(.cardBottom, strength: 2)
        .task { await vm.ensureImagesLoaded(for: invite.profile) }
    }
    
    private func openProfile(_ profile: UserProfile) {
        if ui.selectedProfile == nil {
            ui.selectedProfile = profile
        }
    }
}
