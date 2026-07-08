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
    //Non-nil while this card owns the quick invite: the card renders its expanded
    //invite state on top and morphs between the two inside its own feed cell.
    var quickInvite: QuickInvite? = nil

    private let cardCornerRadius: CGFloat = 22
    private let cardHeightRatio: CGFloat = 1.08   // card height = width × this

    @State private var image: UIImage?
    @State private var detailsFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero
    //Collapsed footprint in the cell's space — the invite flight departs from and returns to it.
    @State private var sourceFrame: CGRect = .zero

    private var displayImage: UIImage {
        image ?? profile.image
    }

    //True while the quick-invite flight owns this card's image: the image hides
    //instantly (pixel-covered by the flight copy) and the overlays quick-fade.
    private var quickInviteHidden: Bool { quickInvite != nil }

    var body: some View {
        ZStack(alignment: .top) {
            collapsedCard
            if let quickInvite {
                inviteCard(quickInvite)
            }
        }
        .coordinateSpace(name: SendInviteCard.cellSpace)
    }
}

//Everything the card needs to expand into its send-invite state.
extension ProfileCard {
    struct QuickInvite {
        let vm: TimeAndPlaceViewModel
        let image: UIImage //The image on screen at tap; the flight departs with it
        let images: [UIImage]
        let expanded: Binding<Bool>
        let onExpand: () -> Void //Runs inside the open transaction (the feed scrolls the card to the top)
        let onHide: () -> Void
        let onSend: (EventFieldsDraft) -> Void
    }
}

//Card states
extension ProfileCard {

    private var collapsedCard: some View {
        Image(uiImage: displayImage)
            .profileImageCard(size, hideImage: quickInviteHidden)

            .overlay { backgroundBlur.opacity(quickInviteHidden ? 0 : 1).animation(.easeOut(duration: 0.12), value: quickInviteHidden) }
            //Hide fades (invisible under the opaque flight copy); the reveal is
            //INSTANT — the flight chrome already faded the text back in and lands
            //pixel-identical here, so a second fade would read as a flicker.
            .overlay(alignment: .bottomLeading) { cardOverlay.opacity(quickInviteHidden ? 0 : 1).animation(quickInviteHidden ? .easeOut(duration: 0.12) : nil, value: quickInviteHidden) }

            .profileShrinkPress {onTap(displayImage)}

            .coordinateSpace(name: ProfileCard.cardSpace)
            .task(id: profile.id) { await fetchFirstImage() }
            .profileMorphSource(id: profile.profile.id, cornerRadius: cardCornerRadius)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(SendInviteCard.cellSpace)) } action: { sourceFrame = $0 }
            .customShadow(.card, strength: 4) //Shadow works Nicely Keep!
            .padding(.horizontal, 16) //Feed inset for the collapsed state; the expanded card manages its own gutters
    }

    private func inviteCard(_ invite: QuickInvite) -> some View {
        SendInviteCard(
            vm: invite.vm,
            image: invite.image,
            images: invite.images,
            details: detailsLine,
            expanded: invite.expanded,
            sourceFrame: sourceFrame,
            onExpand: invite.onExpand,
            hideInvite: invite.onHide,
            sendInvite: invite.onSend
        )
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
            //Title font matches the invite card's name overlay, so the quick-invite
            //flight can glide this text with zero visual change.
            Text(profile.profile.name)
                .font(.title(26))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ProfileCard.cardSpace)) } action: { nameFrame = $0 }

            Text(detailsLine)
                .font(.body(14, .medium))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(ProfileCard.cardSpace)) } action: { detailsFrame = $0 }
        }
        .foregroundStyle(Color.white)
        .font(.body(14, .medium))
    }

    //One source for the card and the invite flight, so the flight fades exactly this text.
    private var detailsLine: String {
        let p = profile.profile
        return "\(p.year) | \(p.degree) | \(p.hometown)"
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
    func profileImageCard(_ size: CGFloat, ratio: CGFloat = 1.12, hideImage: Bool = false) -> some View {
        self
            .resizable()
            .scaledToFill()
            .frame(width: max(size, 0), height: max(size, 0) * ratio) //How much taller than wide i.e. 12%
            .clipShape(.rect(cornerRadius: 20, style: .continuous)) //Corner Radius 22
            .opacity(hideImage ? 0 : 1) //Pixel-covered by the quick-invite flight copy; never animated
            .background(Color.appCanvas, in: .rect(cornerRadius: 20, style: .continuous)) //For Shadow
            .customShadow(.card, strength: 4) //Keep Shadow here. Works Nicely
    }
}
