//
//  TimeAndPlaceScreens.swift
//  Scoop
//
//  Created by Art Ostin on 04/05/2026.
//

import SwiftUI



@MainActor
struct RespondTimeAndPlaceView: View {
    @Bindable var vm: RespondViewModel
    let sendInvite: () -> ()
    var event: UserEvent { vm.respondDraft.originalInvite.event }

    var body: some View {
        Text("Hello World")
//        SendInviteContainer(
//            draft: $vm.respondDraft.newEvent,
//            name: event.otherUserName,
//            isInviteResponse: true,
//            defaults: vm.defaults,
//            onSendInvite: sendInvite
//        )
    }
}
