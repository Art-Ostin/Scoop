//
//  InviteSectionContainer.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/07/2026.
//

import SwiftUI

struct InviteSectionContainer: View {
    
    @State var showConfirmScreen = false
    @State var showMessageScreen = false
    
    let name: String
    let defaults: DefaultsManaging
    
    @Binding var draft: EventFieldsDraft
    @Binding var invitePopupOpen: Bool
    
    let onSendInvite: () -> ()
    
    var body: some View {
        
        ZStack {
            if showConfirmScreen {
                confirmInviteScreen
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            } else {
                selectTimeAndPlaceView
            }
        }
        .sheet(isPresented: $showMessageScreen) {addMessageView}
        .animation(Animation.move, value: showConfirmScreen)
    }
}

extension InviteSectionContainer {
    
    private var selectTimeAndPlaceView: some View {
        SelectTimeAndPlace(
            draft: $draft,
            showConfirmScreen: $showConfirmScreen,
            showMessageScreen: $showMessageScreen,
            name: name,
            isInviteResponse: false,
            defaults: defaults,
            onPopupOpenChange: { invitePopupOpen = $0 }
        )
    }
    
    private var confirmInviteScreen: some View {
        ConfirmInviteScreen(
            name: name,
            event: $draft,
            showMessageScreen: $showMessageScreen,
            showConfirmScreen: $showConfirmScreen,
            onSendInvite: onSendInvite
        )
    }
    
    private var addMessageView: some View {
        NavigationStack { //NavStack added for navigationTitle -> stack don't persist in sheets
            AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
        }
    }
}
