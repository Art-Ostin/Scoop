//
//  NewInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct InviteCard: View {

    //1. Open and close profile and morph
    @Environment(ProfileMorphState.self) private var profileMorph: ProfileMorphState?

    //2. Store captured ImageSize
    @Binding var selectedProfile: UserProfile?
    
    //4. Logic to update in container
    @Binding var draft: RespondDraft

    
    //3. Profile to pass in and dimiss logic
    let eventProfile: EventProfile
    let onRespond: () -> Void
    
    @State var profileNameBounds: CGRect = .zero
    

    private var mainImage: UIImage {
        eventProfile.image ?? UIImage()
    }
    
    var body: some View {
        VStack(spacing: 36) {
            GreedyImage(image: eventProfile.image ?? UIImage(), hPadding: 16, aspectRatio: .inviteCard)
                .onTapGesture {openProfile()}
                .profileMorphSource(id: eventProfile.profile.id, radii: .init(uniform: CornerRadius.photoCard))
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
            .padding(.leading, 16)
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
            .padding(12)
            .padding(.top, -4)
    }
}
