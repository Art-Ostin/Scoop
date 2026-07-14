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
    
    let onSendInvite: (EventFieldsDraft) -> ()
    
    
    
    
    var body: some View {
        
        ZStack {
            
        }
        .sheet(isPresented: $showMessageScreen) {
            NavigationStack {
                AddMessageView(message: $draft.message, isRespondMessage: false, eventType: $draft.type)
            }
        }
    }
}

extension InviteSectionContainer {
    
    private var selectTimeAndPlaceView: some View {
        SelectTimeAndPlace(
            draft: $draft,
            showConfirmScreen: $showConfirmScreen,
            name: name,
            isInviteResponse: false,
            defaults: defaults,
            onPopupOpenChange: { invitePopupOpen = $0 }
        )
    }
    
    private var confirmInviteScreen: some View {
        ConfirmInviteScreen(
            name: <#T##String#>,
            event: <#T##Binding<EventFieldsDraft>#>,
            showMessageScreen: <#T##Binding<Bool>#>,
            showConfirmScreen: <#T##Binding<Bool>#>,
            onSendInvite: <#T##() -> ()#>
        )
    }
    
    
    
    
}
