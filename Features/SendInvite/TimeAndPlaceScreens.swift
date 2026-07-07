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

    let image: UIImage
    @Binding var expanded: Bool
    let sourceFrame: CGRect
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void

    var body: some View {
        SendInviteCard(vm: vm, image: image, expanded: $expanded, sourceFrame: sourceFrame, hideInvite: hideInvite, sendInvite: sendInvite)
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
            name: event.otherUserName,
            isInviteResponse: true,
            defaults: vm.defaults,
            onClearDraft: {vm.deleteEventDefault()},
            hideInvite: {},
            onSendInvite: {sendInvite()}
        )
    }
}
