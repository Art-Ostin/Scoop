//
//  ProfileCard.swift
//  ScoopTest
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {

    let onTap: () -> Void
    let onQuickInvite: () -> Void
    let profile: PendingProfile
    let size: CGFloat
    let imageLoader: ImageLoading
    // While a morph is live for this profile, the morph surface *is* the button,
    // so the real one hides to avoid a duplicate during expand/collapse.
    var isMorphing: Bool = false

    private let cardCornerRadius: CGFloat = 22

    @State private var image: UIImage?
    @State private var detailsFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero


    var body: some View {
        Image(uiImage: displayImage)
            .resizable()
            .defaultImage(size, cardCornerRadius)
            .overlay {
                BackgroundBlur(image: displayImage, size: size, frames: [nameFrame, detailsFrame], clipCornerRadius: cardCornerRadius)
            }
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color.appCanvas)
            )
            .customShadow(.card, strength: 4) //Keep Shadow here. Works Nicely
            .overlay(alignment: .bottomLeading) { cardOverlay }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .coordinateSpace(name: ProfileCard.cardSpace)
            .task(id: profile.id) {
                image = try? await imageLoader.fetchFirstImage(profile: profile.profile)
            }
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
            .opacity(isMorphing ? 0 : 1)
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

    // Blurred copy of the image, masked to a feathered rounded-rect that
    // tracks the text's frame — gives a soft halo of blur only behind the text.
    private func backgroundBlur(isDetails: Bool) -> some View {
        Image(uiImage: displayImage)
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0))
            .blur(radius: 22)
            .mask(detailsBlurMask(isDetails: isDetails))
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .allowsHitTesting(false)
    }

    private func detailsBlurMask(isDetails: Bool) -> some View {
        let padX: CGFloat = 4
        let padY: CGFloat = 2
        let feather: CGFloat = 4
        let rect = isDetails ? detailsFrame.insetBy(dx: -padX, dy: -padY) : nameFrame.insetBy(dx: -padX, dy: -padY)
        return RoundedRectangle(cornerRadius: 12)
            .frame(width: max(rect.width, 0), height: max(rect.height, 0))
            .position(x: rect.midX, y: rect.midY)
            .blur(radius: feather)
            .opacity(detailsFrame == .zero ? 0 : 1)
    }
}
