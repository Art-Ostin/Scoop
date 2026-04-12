//
//  InviteCardInfo.swift
//  Scoop
//
//  Created by Art Ostin on 18/03/2026.
//

import SwiftUI

struct InviteCardInfo: View {
    
    @Bindable var vm: RespondViewModel
    @State var ui: RespondUIState
    typealias layout = RespondUIState.CardLayout
    
    let name: String
    let event: UserEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            inviteCardTimeRow
                .padding(.top, layout.titleToTimeSpacing)
            inviteCardPlaceRow
                .padding(.top, layout.timeToPlaceSpacing)
            responseRow
                .padding(.top, layout.actionTopSpacing)
        }
        .padding(.horizontal, 20)
        .padding(.top, layout.topPadding)
        .padding(.bottom, layout.bottomPadding)
    }
}

extension InviteCardInfo {
    
    private var title: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text("\(name)'s Invite")
                .font(.custom("SFProRounded-Bold", size: 20))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InviteRespondButton(type: event.type, showInfo: $ui.showMeetInfo)
                .scaleEffect(0.9, anchor: .trailing)
                .fixedSize()
        }
    }
    
    private var inviteCardTimeRow: some View {
        InviteCardTimeRow(
            selectedDay: vm.respondDraft.originalInvite.selectedDay ,
            showMessageScreen: $ui.showMessageScreen,
            showTimePopup: $ui.showTimePopup,
            vm: vm
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
