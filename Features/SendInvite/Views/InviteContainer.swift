//
//  InviteContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 29/06/2026.
//

import SwiftUI

struct InviteContainer: View {
    @State var vm: TimeAndPlaceViewModel
    @State var showBack: Bool = false
    
    let sendInvite: (EventFieldsDraft) -> Void
    
    var body: some View {
        CardFlipContainer(showBack: $showBack) {
            sendInviteContainer
        } backCard: {
            confirmInviteView
        }
    }
}

extension InviteContainer {
    
    private var sendInviteContainer: some View {
        SendInviteContainer(
            draft: $vm.event,
            showConfirm: $showBack,
            name: vm.inviteModel.name,
            isInviteResponse: false,
            defaults: vm.defaults,
            onClearDraft: {vm.deleteEventDefault()},
            onSendInvite: {sendInvite(vm.event)}
        )
    }
    
    private var confirmInviteView: some View {
        ConfirmInviteScreen(
            draft: vm.event,
            name: vm.inviteModel.name,
            defaults: vm.defaults,
            showConfirmInviteScreen: $showBack
        )
    }
}
