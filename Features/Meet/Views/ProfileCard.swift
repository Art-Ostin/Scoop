//
//  ProfileCard.swift
//  Scoop
//
//  Created by Art Ostin on 09/08/2025.


import SwiftUI

struct ProfileCard : View {

    //Hands back the image actually on screen, so the profile morph flies exactly it.
    let onTap: (UIImage) -> Void
    //Same contract for the quick-invite flight.
    let onQuickInvite: (UIImage) -> Void
    let profile: PendingProfile
    let size: CGFloat
    let imageLoader: ImageLoading
    let quickInviteHidden: Bool

    private let cardCornerRadius: CGFloat = 22

    @State private var image: UIImage?
    @State private var nameFrame: CGRect = .zero
    @State private var detailsFrame: CGRect = .zero

    private var displayImage: UIImage {
        image ?? profile.image
    }

    var body: some View {

        Image(uiImage: displayImage)
            .profileImageCard(size, hideImage: quickInviteHidden)

            .overlay {
                BackgroundBlur(image: displayImage, frames: [nameFrame, detailsFrame])
                    .opacity(quickInviteHidden ? 0 : 1)
                    .animation(.easeOut(duration: 0.12), value: quickInviteHidden)
            }
            .overlay(alignment: .bottomLeading) { cardOverlay.opacity(quickInviteHidden ? 0 : 1).animation(quickInviteHidden ? .easeOut(duration: 0.12) : nil, value: quickInviteHidden) }

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
        InviteButton(isInviting: true, morphId: profile.profile.id) {
            onQuickInvite(displayImage)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let p = profile.profile
            Text(p.name)
                .font(.title(26))
                .getViewsRect($nameFrame, coordSpace: ProfileCard.cardSpace)

            Text("\(p.year) | \(p.degree) | \(p.hometown)")
                .font(.body(14, .medium))
                .getViewsRect($detailsFrame, coordSpace: ProfileCard.cardSpace)
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }
    
    func fetchFirstImage() async {
        image = try? await imageLoader.fetchFirstImage(profile: profile.profile)
    }
}

extension ProfileCard {
    fileprivate static let cardSpace = "ProfileCard.card"
}

extension Image {

    func profileImageCard(_ size: CGFloat, ratio: CGFloat = 1.12, hideImage: Bool = false) -> some View {
        self
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0) * ratio) //How much taller than wide i.e. 12%
            .clipShape(.rect(cornerRadius: 20, style: .continuous)) //Corner Radius 22
            .opacity(hideImage ? 0 : 1) //Pixel-covered by the quick-invite flight copy; never animated
            //Canvas fill exists only to give the shadow a shape — hidden with the image so the
            //reserved slot renders NOTHING behind a swipe-dismiss drag (the layout gap remains).
            .background(hideImage ? Color.clear : Color.appCanvas, in: .rect(cornerRadius: 20, style: .continuous))
            .customShadow(.card, strength: 4) //Keep Shadow here. Works Nicely
    }
}
