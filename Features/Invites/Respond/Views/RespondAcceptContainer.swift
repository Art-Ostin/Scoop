//
//  RespondAcceptContainer.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondAcceptContainer: View {
    
    //Injected
    @Bindable var vm: RespondViewModel
    @Binding var confirmNewTimeInvite: Bool
    @Binding var confirmAcceptInvite: Bool
    let onDecline: () -> Void

    //Local view state
    @State private var ui = RespondUIState()
    
    var body: some View {
        CardFlipContainer(showBack: $ui.showMeetInfo) {
            respondCard
                .offset(y: 16)
        } backCard: {
            respondDetails
        }
        .padding(.top, Spacing.xl)
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
