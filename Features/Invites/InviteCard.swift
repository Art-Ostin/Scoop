//
//  InviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 13/03/2026.
//

import SwiftUI

struct InviteCard: View {
    
    let eventProfile: EventProfile
    
    var body: some View {
        Text(eventProfile.profile.name)
        Text(eventProfile.event.location.name ?? "No location name")
    }
}
