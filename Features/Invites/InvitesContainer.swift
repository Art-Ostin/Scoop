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
            InvitesPlaceholder()
        } else {
            InvitesView()
        }
    }
}

