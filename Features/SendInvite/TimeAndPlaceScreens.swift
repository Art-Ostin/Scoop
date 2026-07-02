//
//  TimeAndPlaceConstructors.swift
//  Scoop
//
//  Created by Art Ostin on 04/05/2026.
//

import SwiftUI

@MainActor
struct InviteTimeAndPlaceView: View {
    @State var vm: TimeAndPlaceViewModel
    let sendInvite: (EventFieldsDraft) -> Void
    var requestConfirm: ((@escaping () -> Void) -> Void)? = nil

    var body: some View {
        InviteContainer(vm: vm, sendInvite: sendInvite)
    }
}

@MainActor
struct RespondTimeAndPlaceView: View {
    @Bindable var vm: RespondViewModel
    let sendInvite: () -> ()
    var event: UserEvent { vm.respondDraft.originalInvite.event }

    var body: some View {
        SendInviteContainer(
            draft: $vm.respondDraft.newEvent,
            showConfirm: .constant(false),
            name: event.otherUserName,
            isInviteResponse: true,
            defaults: vm.defaults,
            onClearDraft: {vm.deleteEventDefault()},
            onSendInvite: {sendInvite()}
        )
    }
}

/*
 SendInviteContainer(
     draft: $vm.event,
     name: vm.inviteModel.name,
     image: vm.inviteModel.image,
     deleteEventDefault: {vm.deleteEventDefault()},
     onSendInvite: {sendInvite(vm.event)},
     isInviteResponse: false,
     defaults: vm.defaults,
     requestConfirm: requestConfirm
 )
 */
