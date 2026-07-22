//
//  InviteSlot.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteSlot: View {
    
    let eventProfile: EventProfile
    @Binding var draft: RespondDraft
    @Binding var openInvite: Bool

    var body: some View {
        VStack(spacing: 72) {
            inviteCard
            CustomDivider().padding(.horizontal, 72)
            InviteCardInfoPager(event: eventProfile)
        }
    }
    
    @ViewBuilder
    private var inviteCard: some View {
        if let image = eventProfile.image {
            InviteCard(image: image, name: eventProfile.profile.name, draft: $draft, openInvite: $openInvite)
        }
    }
}


