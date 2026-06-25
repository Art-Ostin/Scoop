//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {

    //Hands back the image actually on screen, so the profile morph flies exactly it.
    let onTap: (UIImage) -> Void
    let onQuickInvite: () -> Void
    let profile: PendingProfile
    let size: CGFloat
    let imageLoader: ImageLoading

    private let cardCornerRadius: CGFloat = 22
    private let cardHeightRatio: CGFloat = 1.08   // card height = width × this

    @State private var image: UIImage?
    @State private var detailsFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero


    var body: some View {
        Image(uiImage: displayImage)
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0) * cardHeightRatio)
            .clipShape(.rect(cornerRadius: cardCornerRadius, style: .continuous))

        
//            .defaultImage(size, cardCornerRadius)
        
        
        
        
            .overlay {
                BackgroundBlur(image: displayImage, size: CGSize(width: size, height: size * cardHeightRatio), frames: [nameFrame, detailsFrame], clipCornerRadius: cardCornerRadius)
            }
            .background(Color.appCanvas, in: .rect(cornerRadius: cardCornerRadius, style: .continuous))
            .customShadow(.card, strength: 4) //Keep Shadow here. Works Nicely
            .overlay(alignment: .bottomLeading) { cardOverlay }
            .contentShape(Rectangle())
            .onTapGesture { onTap(displayImage) }
            .coordinateSpace(name: ProfileCard.cardSpace)
            .task(id: profile.id) {
                image = try? await imageLoader.fetchFirstImage(profile: profile.profile)
            }
            .profileMorphSource(id: profile.profile.id, cornerRadius: cardCornerRadius)
    }

    private var displayImage: UIImage {
        image ?? profile.image
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
    }

    private var inviteButton: some View {
        InviteButton(isInviting: true, morphId: profile.profile.id, action: onQuickInvite)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let p = profile.profile
            Text(p.name)
                .font(.body(22, .bold))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ProfileCard.cardSpace)) } action: { nameFrame = $0 }

            Text("\(p.year) | \(p.degree) | \(p.hometown)")
                .font(.body(14, .medium))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ProfileCard.cardSpace)) } action: { detailsFrame = $0 }
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
}

extension ProfileCard {

    fileprivate static let cardSpace = "ProfileCard.card"
}
