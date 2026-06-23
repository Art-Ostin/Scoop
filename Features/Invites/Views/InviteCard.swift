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
            .overlay {
                BackgroundBlur(image: mainImage, size: CGSize(width: imageSize, height: imageSize + 170), frames: [profileNameBounds], clipCornerRadius: 24)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    profileName
                    inviteCardInfo
                }
            }
            .coordinateSpace(name: "ProfileCard")
    }
}

extension InviteCard {
    
    private var profileName: some View {
        HStack {
            Text("\(eventProfile.profile.name)'s Invite")
                .font(.body(22, .bold))
                .foregroundStyle(Color.white)
                .onGeometryChange(for: CGRect.self) { geo in
                    geo.frame(in: .named("ProfileCard"))
                } action: { nameLocation in
                    profileNameBounds = nameLocation
                }
                .padding(.leading, 16)
            Spacer()
        }
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
        InviteCardInfo(eventProfile: eventProfile, onRespond: onRespond)
            .padding(12)
            .padding(.top, -4)
    }

}

