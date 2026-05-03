//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardEvent: View {
    
    @Binding var showMessageSection: Bool
    @Binding var showConfirmAcceptInvite: String?
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondUIState
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
            showTimePopup: $ui.showTimePopup,
            vm: vm)
    }
    
    private var inviteCardPlaceRow: some View {
        InviteCardPlaceRow(location: event.location, isMeetUp: false) {MapsRouter.openMaps(defaults: vm.defaults)}
            .opacity(ui.showTimePopup ? 0.2 : 1)
    }
    
    @ViewBuilder
    private var responseRow: some View {
        let type: Event.EventType = vm.respondDraft.originalInvite.event.type
        let timeCount: Int = vm.respondDraft.newTime.proposedTimes.dates.count
        let isValid: Bool = (
            ((type == .drink || type == .doubleDate) && timeCount >= 2) ||
            ((type == .custom || type == .socialMeet) && timeCount >= 1)
        )
        
        HStack {
            DeclineButton { onDecline(vm.respondDraft.originalInvite.event)}
            Spacer()
            AcceptButton(isModified: isModified, isValid: isValid) {
                showConfirmAcceptInvite = vm.respondDraft.originalInvite.event.otherUserId
            }
        }
        .opacity(ui.showTimePopup ? 0.1 : 1)
        .allowsHitTesting(!ui.showTimePopup)
    }
}
 struct QuickInviteTime: PreferenceKey {
     static var defaultValue: Bool = false
     static func reduce(value: inout Bool, nextValue: () -> Bool) {
         value = nextValue()
     }
 }

