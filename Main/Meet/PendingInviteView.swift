//
//  PendingInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 25/10/2025.
//

import SwiftUI

struct PendingInviteCard: View {
    
    @Binding var showInvitedProfile: ProfileModel
    
    @Bindable var vm: MeetViewModel
    
    
    var body: some View {

        ScrollView(.vertical) {
            ForEach(vm.pendingInvites) { invite in
                PendingInviteCard(showInvitedProfile: $showInvitedProfile, vm: vm)
            }
        }
    }
}
