//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardEvent: View {

    @Binding var showMessageSection: Bool

    @Binding var showAcceptPopup: String?
    @Binding var showNewTimePopup: String?

    @Bindable var vm: RespondViewModel
    @Binding var showTimePopup: Bool
    typealias layout = RespondUIState.CardLayout

    var event: UserEvent {vm.respondDraft.originalInvite.event}
    var isModified: Bool {vm.responseType == .modified}
    let onDecline: (UserEvent) -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inviteCardTimeRow
                .padding(.top, layout.titleToTimeSpacing)
            inviteCardPlaceRow
                .padding(.top, layout.timeToPlaceSpacing)
            responseRow
                .padding(.top, layout.actionTopSpacing)
        }
        .padding(.bottom, RespondUIState.CardLayout.bottomPadding)
    }
}

extension InviteCardEvent {
    
    private var inviteCardTimeRow: some View {
        InviteCardTimeRow(
            showTimePopup: $showTimePopup,
            vm: vm)
    }

    private var inviteCardPlaceRow: some View {
        InviteCardPlaceRow(location: event.location, isMeetUp: false) {
            MapsRouter.openMaps(defaults: vm.defaults, item: event.location.mapItem, withDirections: true)
        }
        .disabled(showTimePopup)
        .opacity(showTimePopup ? 0.2 : 1)
    }
    
    @ViewBuilder
    private var responseRow: some View {
        HStack {
            DeclineButton { onDecline(vm.respondDraft.originalInvite.event)}
            Spacer()
            AcceptButton(isModified: isModified, isValid: vm.respondDraft.canSendNewTime) {
                if isModified {
                    showNewTimePopup = event.id
                } else {
                    showAcceptPopup = event.id
                }
            }
        }
        .opacity(showTimePopup ? 0.1 : 1)
        .allowsHitTesting(!showTimePopup)
    }
}

