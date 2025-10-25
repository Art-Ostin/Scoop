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
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 48) {
                ForEach(vm.pendingInvites) { invite in
                    PendingInviteCard(profile: invite, showInvitedProfile: $showInvitedProfile)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}
