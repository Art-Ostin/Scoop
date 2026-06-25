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
    
    private var displayImage: UIImage {
        image ?? profile.image
    }

    var body: some View {
        
        Image(uiImage: displayImage)
            .meetImageCard(size)
        
            .overlay { backgroundBlur }
            .overlay(alignment: .bottomLeading) { cardOverlay }
        
            .profileShrinkPress {onTap(displayImage)}

            .coordinateSpace(name: ProfileCard.cardSpace)
            .task(id: profile.id) { await fetchFirstImage() }
            .profileMorphSource(id: profile.profile.id, cornerRadius: cardCornerRadius)
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
    
    private var backgroundBlur: some  View {
        BackgroundBlur(
            image: displayImage,
            size: CGSize(width: size, height: size * cardHeightRatio),
            frames: [nameFrame, detailsFrame],
            clipCornerRadius: cardCornerRadius
        )
    }
    
    func fetchFirstImage() async {
        image = try? await imageLoader.fetchFirstImage(profile: profile.profile)
    }
}

extension ProfileCard {
    fileprivate static let cardSpace = "ProfileCard.card"
}

extension Image {
    func meetImageCard(_ size: CGFloat) -> some View {
        self
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0) * 1.08) //How much taller than wide i.e. 8%
            .clipShape(.rect(cornerRadius: 22, style: .continuous)) //Corner Radius 22
            .customShadow(.card, strength: 4) //Keep Shadow here. Works Nicely
    }
}
