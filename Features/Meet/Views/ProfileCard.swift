//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    @State private var nameFrame: CGRect = .zero
    @State private var detailsFrame: CGRect = .zero
    
    let cardSpace = "ProfileCard"
    
    let profile: PendingProfile
    let quickInviteHidden: Bool

    let onTap: (UIImage) -> Void
    let onQuickInvite: (UIImage) -> Void
    
    var body: some View {
        ScoopImage(image: profile.image, showShadow: true)
            .opacity(quickInviteHidden ? 0 : 1)
            .overlay {backgroundBlur}
            .overlay(alignment: .bottomLeading) {cardOverlay}
            .profileShrinkPress {onTap(profile.image)}
            .coordinateSpace(name: cardSpace)
            .profileMorphSource(id: profile.profile.id, cornerRadius: CornerRadius.photoCard)
    }
}

extension ProfileCard {
    

    private var cardOverlay: some View {
        HStack(alignment: .bottom) {
            infoSection
            Spacer()
            inviteButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .opacity(quickInviteHidden ? 0 : 1)
        .animation(quickInviteHidden ? .easeOut(duration: 0.12) : nil, value: quickInviteHidden)
    }

    private var inviteButton: some View {
        InviteButton(isInviting: true, morphId: profile.profile.id) {
            onQuickInvite(profile.image)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let p = profile.profile
            Text(p.name)
                .font(.title(26))
                .getRect($nameFrame, coordSpace: cardSpace)

            Text("\(p.year) | \(p.degree) | \(p.hometown)")
                .font(.body(14, .medium))
                .getRect($detailsFrame, coordSpace: cardSpace)
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
    
    private var backgroundBlur: some View {
        BackgroundBlur(image: profile.image, frames: [nameFrame, detailsFrame])
            .opacity(quickInviteHidden ? 0 : 1)
            .animation(.easeOut(duration: 0.12), value: quickInviteHidden)
    }
}
