//
//  PendingInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct PendingInviteView: View {
    @Binding var showInvitedProfile: ProfileModel?
    @Bindable var vm: MeetViewModel
    
    @Binding var showPendingInvites: Bool
    @Binding var wasInviteSelected: Bool
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 48) {
                ForEach(vm.pendingInvites) { invite in
                    PendingInviteCard(profile: invite, showInvitedProfile: $showInvitedProfile, showPendingInvites: $showPendingInvites, wasInviteSelected: $wasInviteSelected)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}
