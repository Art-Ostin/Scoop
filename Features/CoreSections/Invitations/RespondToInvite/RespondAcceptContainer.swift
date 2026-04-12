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
        
        ZStack {
            if !ui.showMeetInfo {
                RespondAcceptCard(vm: vm, ui: ui)
                .zIndex(0)
            } else {
                let event = vm.respondDraft.originalInvite.event
                RespondDetailsView(event: event, showInfo: $ui.showMeetInfo, image: vm.image)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(ui.showMeetInfo ? 180 : 0), axis: (x: 0, y:1, z:0))
        .animation(.easeInOut, value: ui.showMeetInfo)
    }
}
