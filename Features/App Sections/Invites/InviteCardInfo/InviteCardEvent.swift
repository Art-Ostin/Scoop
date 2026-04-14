//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardEvent: View {
    
    @Binding var showMessageSection: Bool
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondUIState
    typealias layout = RespondUIState.CardLayout
    
    var event: UserEvent { vm.respondDraft.originalInvite.event}
    
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
            selectedDay: vm.respondDraft.originalInvite.selectedDay ,
            showTimePopup: $ui.showTimePopup,
            vm: vm)
    }
    
    private var inviteCardPlaceRow: some View {
        InviteCardPlaceRow(location: event.location) { ui.selectedTab = .message}
            .opacity(ui.showTimePopup ? 0.2 : 1)
    }
        
    private var responseRow: some View {
        HStack {
            DeclineButton { }
            Spacer()
            AcceptButton {}
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

