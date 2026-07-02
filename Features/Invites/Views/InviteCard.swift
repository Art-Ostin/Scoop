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
        VStack(spacing: 36) {
            Image(uiImage: eventProfile.image ?? UIImage())
                .profileImageCard(imageSize, ratio: 1.5)
                .onTapGesture {openProfile()}
                .profileMorphSource(id: eventProfile.profile.id, radii: .init(uniform: 24))
                .overlay {backgroundBlur}
                .overlay(alignment: .bottomLeading) {inviteCardOverlay}
                .coordinateSpace(name: "ProfileCard")
            
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.8))
                .frame(maxWidth: .infinity, maxHeight: 1)
                .padding(.horizontal, 72)
                .padding(.vertical, 4)
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
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("ProfileCard")) } action: { profileNameBounds = $0 }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
    }

    private var profileImage: some View {
        Image(uiImage: eventProfile.image ?? UIImage())
            .profileImageCard(imageSize, ratio: 1.25)
            .onTapGesture {openProfile()}
    }
    
    private var backgroundBlur: some View {
        BackgroundBlur(image: mainImage, size: CGSize(width: imageSize, height: imageSize + 170), frames: [profileNameBounds], clipCornerRadius: 24)
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


struct HorizontalScrollViewTest<Element: Hashable>: View {
    let iterable: [Element]
    
    let pageWidth: CGFloat
    
    var body: some View {
        
        ScrollView(.horizontal) {
            HStack {
                ForEach(iterable, id: \.self) { item in
                    
                    
                }
            }
            .scrollTargetLayout()
        }
    }
}
