//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct InviteCard: View {

    //Injected
    @Environment(ProfileMorphState.self) private var profileMorph: ProfileMorphState?
    @Binding var selectedProfile: UserProfile?
    @Binding var draft: RespondDraft
    let eventProfile: EventProfile
    let onRespond: () -> Void

    //Local view state
    @State private var profileNameBounds: CGRect = .zero

    private var mainImage: UIImage {
        eventProfile.image ?? UIImage()
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ScoopImage(image: eventProfile.image ?? UIImage(), aspectRatio: .inviteCard, showShadow: true)
                .onTapGesture {openProfile()}
                .profileMorphSource(id: eventProfile.profile.id, radii: .init(uniform: CornerRadius.image))
                .overlay {BackgroundBlur(image: mainImage, frames: [profileNameBounds])}
                .overlay(alignment: .bottomLeading) {inviteCardOverlay}
                .coordinateSpace(name: "ProfileCard")

            LightDivider()
        }
    }
}

extension InviteCard {
        
    private var inviteCardOverlay: some View {
        VStack(spacing: 0) {
            profileName
            inviteCardInfo
        }
    }
    
    private var profileName: some View {
        Text("\(eventProfile.profile.name)'s Invite")
            .font(.body(22, .bold))
            .foregroundStyle(Color.white)
            .getRect($profileNameBounds, coordSpace: "ProfileCard")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Spacing.md)
    }

    private func openProfile() {
        guard selectedProfile == nil else { return }
        profileMorph?.beginOpen(id: eventProfile.profile.id, image: eventProfile.image)
        selectedProfile = eventProfile.profile
    }
}

extension InviteCard {
    
    private var inviteCardInfo: some View {
        InviteCardInfo(draft: $draft, eventProfile: eventProfile, onRespond: onRespond)
            .padding(Spacing.sm)
            .padding(.top, -4)
    }
}
