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
    @Binding var openInvite: EventProfile?
    let profileImages: [UIImage]
    let profileView: () -> AnyView

    @State private var profileTrigger = 0

    var body: some View {
        VStack(spacing: 72) {
            inviteCard
                .zoomTransition(images: profileImages, trigger: profileTrigger) {
                    profileView()
                }
                .onTapGesture { profileTrigger += 1 }
                .padding(.top, -Spacing.md)
            
            CustomDivider().padding(.horizontal, 72)
            InviteInfo(event: eventProfile)
        }
    }
    
    @ViewBuilder
    private var inviteCard: some View {
        if let image = eventProfile.image {
            InviteCard( image: image, name: eventProfile.profile.name, draft: $draft) {
                openInvite = eventProfile
            }
        }
    }
}
