//
//  RespondAcceptContainer.swift
//  Scoop
//
//  Created by Art Ostin on 21/03/2026.
//

import SwiftUI

struct RespondAcceptContainer: View {
    
    @Bindable var vm: RespondViewModel
    @State var ui = RespondUIState()
    
    var body: some View {
        
        ZStack(alignment: .top) {
            RespondAcceptCard(vm: vm, ui: ui)
                .opacity(ui.showMeetInfo ? 0 : 1)
                .allowsHitTesting(!ui.showMeetInfo)
                .zIndex(ui.showMeetInfo ? 0 : 1)
                .offset(y: 16)
            
            RespondDetailsView(event: vm.respondDraft.originalInvite.event, showInfo: $ui.showMeetInfo, image: vm.image)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(ui.showMeetInfo ? 1 : 0)
                .allowsHitTesting(ui.showMeetInfo)
                .zIndex(ui.showMeetInfo ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 32)
        .rotation3DEffect(.degrees(ui.showMeetInfo ? 180 : 0), axis: (x: 0, y:1, z:0))
        .animation(.easeInOut, value: ui.showMeetInfo)
        .preference(key: IsTimeOpen.self, value: ui.showTimePopup)
    }
}
