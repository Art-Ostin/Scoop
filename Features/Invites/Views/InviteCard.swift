//
//  NewInviteCard.swift
//  Scoop Test
//
//  Created by Art Ostin on 06/06/2026.
//

import SwiftUI

struct InviteCard: View {

    //1. Open and close profile and morph
    @Environment(ProfileMorphState.self) private var profileMorph: ProfileMorphState?
    var isMorphing: Bool = false
    
    //2. Store captured ImageSize
    @Binding var selectedProfile: UserProfile?
    
    //4. Logic to update in container
    @Binding var draft: RespondDraft

    
    //3. Profile to pass in and dimiss logic
    let eventProfile: EventProfile
    let imageSize: CGFloat
    let onRespond: () -> Void
    
    @State var profileNameBounds: CGRect = .zero
    

    private var mainImage: UIImage {
        eventProfile.image ?? UIImage()
    }
    
    var body: some View {
        profileImage
            .overlay {backgroundBlur}
            .overlay(alignment: .bottomLeading) {inviteCardOverlay}
            .coordinateSpace(name: "ProfileCard")
    }
}

extension InviteCard {
    
    private var backgroundBlur: some View {
        BackgroundBlur(image: mainImage, size: CGSize(width: imageSize, height: imageSize + 170), frames: [profileNameBounds], clipCornerRadius: 24)
    }
    
    private var inviteCardOverlay: some View {
        VStack(spacing: 0) {
            profileNameView
            inviteCardInfo
        }
    }
    
    private var profileNameView: some View {
        profileName
            .onGeometryChange(for: CGRect.self) {geo in
                geo.frame(in: .named("ProfileCard"))
            } action: { nameLocation in
                profileNameBounds = nameLocation
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
    }

    private var profileName: some View {
        Text("\(eventProfile.profile.name)'s Invite")
            .font(.body(22, .bold))
            .foregroundStyle(Color.white)
    }

    private var profileImage: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: max(imageSize, 0), height: max(imageSize, 0) + 170) //Have slightly long Image
            .clipShape(.rect(cornerRadius: 16))
            .background(Color.appCanvas, in: .rect(cornerRadius: 24))
            .customShadow(.cardBottom, strength: 2) //Bottom-biased shadow: no halo above the top edge
            .onTapGesture {openProfile()}
            .profileMorphSource(id: eventProfile.profile.id, radii: .init(uniform: 24))
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

