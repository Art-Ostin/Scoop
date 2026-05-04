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
    @Binding var showInvite: String?
    let sendInvite: (EventFieldsDraft) -> Void
    
    var body: some View {
        SelectTimeAndPlace(
            draft: $vm.event,
            showInvite: $showInvite,
            name: vm.inviteModel.name,
            image: vm.inviteModel.image,
            deleteEventDefault: {vm.deleteEventDefault()},
            onSendInvite: {sendInvite(vm.event)},
            isInviteResponse: false,
            defaults: vm.defaults
        )
    }
}

@MainActor
struct RespondTimeAndPlaceView: View {
    @Bindable var vm: RespondViewModel
    @Binding var showInvite: String?
    let sendInvite: (String) -> ()
    var event: UserEvent { vm.respondDraft.originalInvite.event }
    
    var body: some View {
        SelectTimeAndPlace(
            draft: $vm.respondDraft.newEvent,
            showInvite: $showInvite,
            name: event.otherUserName,
            image: vm.image,
            deleteEventDefault: {vm.deleteEventDefault()},
            onSendInvite: { sendInvite(event.otherUserId)},
            isInviteResponse: true,
            defaults: vm.defaults
        )
    }
}
