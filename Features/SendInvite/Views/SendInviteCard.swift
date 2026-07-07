//
//  SendInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

struct SendInviteCard: View {
    
    @State var vm: TimeAndPlaceViewModel

    let image: UIImage
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void
    
    var body: some View {
        
        VStack(spacing: 12)  {
            ScoopImage(image: image, hPadding: 0)
                .onTapGesture {hideInvite()}
            sendInviteContainer
        }
        .modifier(InviteCardBackground())
    }
}

extension SendInviteCard {
    
    private var sendInviteContainer: some View {
        SendInviteContainer(
            draft: $vm.event,
            name: vm.inviteModel.name,
            isInviteResponse: false,
            defaults: vm.defaults,
            onClearDraft: {vm.deleteEventDefault()},
            hideInvite: hideInvite,
            onSendInvite: {sendInvite(vm.event)}
        )
    }
}

struct InviteCardBackground: ViewModifier {
    
    func body(content: Content) -> some View {
        content
        
    }
}
