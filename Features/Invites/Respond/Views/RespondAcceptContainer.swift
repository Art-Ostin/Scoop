//
//  RespondAcceptContainer.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondAcceptContainer: View {
    
    @Bindable var vm: RespondViewModel
    @Binding var confirmNewTimeInvite: Bool
    @Binding var confirmAcceptInvite: Bool
    @State var ui = RespondUIState()
    
    let onDecline: () -> Void
    
    var body: some View {
        CardFlipContainer(showBack: $ui.showMeetInfo) {
            respondCard
                .offset(y: 16)
        } backCard: {
            respondDetails
        }
        .padding(.top, 32)
    }
}

extension RespondAcceptContainer {
    private var respondCard: some View {
        RespondCard(
            vm: vm,
            ui: ui,
            confirmNewTimePopup: $confirmNewTimeInvite,
            confirmAcceptInvite: $confirmAcceptInvite) {
                onDecline()
            }
    }
    
    private var respondDetails: some View {
        RespondDetails(
            event: vm.respondDraft.originalInvite.event,
            showInfo: $ui.showMeetInfo, image: vm.image
        )
    }
}
