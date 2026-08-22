//
//  PendingInvitesView.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/08/2026.
//

import SwiftUI

struct PendingInvitesView: View {
    
    let sentInvites: [EventProfile]
    
    var body: some View {
        ForEach(sentInvites, id: \.self) {invite in
            Text(invite.profile.name)
        }
    }
}
