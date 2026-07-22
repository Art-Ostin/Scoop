//
//  InviteSlot.swift
//  Scoop Test
//
//  Created by Art Ostin on 22/07/2026.
//

import SwiftUI

struct InviteSlot: View {

    @Environment(ProfileMorphState.self) private var profileMorph: ProfileMorphState?

    let eventProfile: EventProfile
    @Binding var draft: RespondDraft
    @Binding var openInvite: Bool
    @Binding var openProfile: UserProfile?

    var body: some View {
        VStack(spacing: 72) {
            inviteCard
                .profileMorphSource(id: eventProfile.profile.id, radii: .init(top: 0, bottom: CornerRadius.image))
                .onTapGesture {presentProfile()}
            CustomDivider().padding(.horizontal, 72)
            InviteInfo(event: eventProfile)
        }
    }
    
    @ViewBuilder
    private var inviteCard: some View {
        if let image = eventProfile.image {
            InviteCard(image: image, name: eventProfile.profile.name, draft: $draft, openInvite: $openInvite)
        }
    }

    private func presentProfile() {
        guard openProfile == nil else { return }
        profileMorph?.beginOpen(id: eventProfile.profile.id, image: eventProfile.image)
        openProfile = eventProfile.profile
    }
}
