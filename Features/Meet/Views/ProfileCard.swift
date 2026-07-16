//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {
    
    //Injected
    let profile: PendingProfile
    let quickInviteHidden: Bool
    let onTap: (UIImage) -> Void
    let onQuickInvite: (UIImage) -> Void

    //Local view state
    @State private var nameFrame: CGRect = .zero
    @State private var detailsFrame: CGRect = .zero
    private let cardSpace = "ProfileCard"

    //The zoom hides only the image view — the caption/button chrome drawn over
    //it must hide too, or it floats over the flight and the empty slot.
    private var zoomFlying: Bool { ImageZoom.isFlying(profile.profile.id) }

    var body: some View {
        ScoopImage(image: profile.image, showShadow: false, zoomSourceID: profile.profile.id) //ImageZoom flies the profile out of this image
            .opacity(quickInviteHidden ? 0 : 1)
            .overlay {backgroundBlur}
            .overlay(alignment: .bottomLeading) {cardOverlay}
            .contentShape(Rectangle()) //The UIKit-backed image has no implicit hit shape — without this, taps on the image miss the button
            .profileShrinkPress {onTap(profile.image)}
            .coordinateSpace(name: cardSpace)
            .sendInviteSource(id: profile.profile.id) //Reports this card's frame as the quick-invite flight source
    }
}

extension ProfileCard {

    private var cardOverlay: some View {
        HStack(alignment: .bottom) {
            infoSection
            Spacer()
            inviteButton
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal)
        .opacity(quickInviteHidden || zoomFlying ? 0 : 1)
        .animation(quickInviteHidden ? .easeOut(duration: 0.12) : nil, value: quickInviteHidden)
        .animation(zoomFlying ? nil : .quick, value: zoomFlying) //Hide instantly (any fade lingers over the flight); restore with a fade
    }

    private var inviteButton: some View {
        InviteButton(isInviting: true) {
            onQuickInvite(profile.image)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
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
            .opacity(quickInviteHidden || zoomFlying ? 0 : 1)
            .animation(.easeOut(duration: 0.12), value: quickInviteHidden)
            .animation(zoomFlying ? nil : .quick, value: zoomFlying) //Hide instantly; the light blur band reads as a white flash if it fades
    }
}
