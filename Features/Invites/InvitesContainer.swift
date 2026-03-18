//
//  InvitesContainer.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InvitesContainer: View {
    
    @State var ui = InvitesUIState()
    @State var vm: InvitesViewModel
    
    var body: some View {
        if vm.invites.isEmpty {
            invitesPlaceholder
        } else {
            invitesView
        }
    }
}

extension InvitesContainer {
    
    private var invitesView: some View {
        VStack(spacing: 36) {
            titleAndTab
            
            ForEach(vm.invites) { invite in
                InviteCard(eventProfile: invite)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .background(Color.background)
    }
    
    private var invitesTabView: some View {
        
        ForEach(vm.invites) { invite in
            InviteCard(eventProfile: invite)
        }
    }
    
    private var titleAndTab: some View {
        ZStack(alignment: .top) {
            Text("Invites")
                .font(.custom("SFProRounded-Bold", size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
            
            TabInfoButton(showScreen: $ui.showInfo)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    
    private var invitesPlaceholder: some View {
        Text("There are no current invites")
    }
}
