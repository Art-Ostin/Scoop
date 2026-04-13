//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardEvent: View {
    
    @Bindable var vm: RespondViewModel
    @Bindable var ui: RespondUIState
    typealias layout = RespondUIState.CardLayout
    
    let name: String
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
    }
}

extension InviteCardEvent {
    
    
    private var inviteCardTimeRow: some View {
        InviteCardTimeRow(
            selectedDay: vm.respondDraft.originalInvite.selectedDay ,
            showTimePopup: $ui.showTimePopup,
            vm: vm,
            useDropDown: false
        )
    }
    
    private var inviteCardPlaceRow: some View {
        InviteCardPlaceRow(
            showMessageSection: $ui.showMessageScreen,
            location: event.location
        )
            .opacity(ui.showTimePopup ? 0.3 : 1)
    }
        
    private var responseRow: some View {
        HStack {
            DeclineButton { }
            Spacer()
            AcceptButton {}
        }
        .opacity(ui.showTimePopup ? 0.3 : 1)
        .allowsHitTesting(!ui.showTimePopup)
    }
    
}
 struct QuickInviteTime: PreferenceKey {
     static var defaultValue: Bool = false
     static func reduce(value: inout Bool, nextValue: () -> Bool) {
         value = nextValue()
     }
 }
