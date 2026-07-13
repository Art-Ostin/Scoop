//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

//The invite card's single image surface — SendInviteCard animates its frame between the
//profile card's rect and the expanded image slot, and everything here rides that same
//transaction, keyed on `expanded`. Collapsed it renders exactly as ProfileCard's image
//(uniform edge-to-edge clip, name/details/invite-button chrome); expanded it is the
//settled carousel (inset pages, "Meet <name>", options menu, page dots). There is no
//separate flight copy, so both endpoints are exact by construction.
struct InviteImageCarousel: View {
    //Injected
    let images: [UIImage]
    let name: String
    let details: String
    let expanded: Bool
    @Binding var scrollProgress: Double
    @Binding var pagerPosition: ScrollPosition
    let coverImage: UIImage? //Close-from-page-N: the page flying home, over the snapped-to page 0 (see SendInviteCard.prepareClose)
    let vm: TimeAndPlaceViewModel //@Observable class — drives the options menu (clear draft)
    var pagingDisabled: Bool = false //Locked while the frame animates or a swipe-dismiss owns the touch
    var optionsVisible: Bool = true //Flips at drag release (not spring completion) so the menu pops back riding the spring-back

    //Local view state
    @State private var meetFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero
    @State private var inviteButtonPopped = false
    @State private var showInfoScreen = false //"How Invites Work" sheet, opened from the options menu

    private static let imageSpace = "InviteImageCarousel.image"
    //Name inset from the image edge (the halo mask measures against these)
    static let nameLeadingInset: CGFloat = 17
    static let nameTopInset: CGFloat = 12
    static let imagePadding: CGFloat = 3 //Geometry: concentric inset of the pages inside the image slot (pairs with CardImageCarousel.imagePadding)

    var body: some View {
        ImageCarousel(
            images: images,
            hPadding: inset,
            topRadius: topRadius,
            bottomRadius: bottomRadius,
            aspectRatio: .card,
            fillsContainerHeight: true, //The animated frame owns the height at both endpoints
            showFade: expanded, //Collapsed: no edge fade, so the close lands on ProfileCard's plain image (no appCanvas sliver)
            scrollProgress: $scrollProgress,
            scrollPosition: $pagerPosition
        )
        .scrollDisabled(images.count <= 1 || pagingDisabled)
        .overlay(alignment: .bottom) { pageIndicator }
        .padding(.top, inset)
        .overlay { closeCover }
        .overlay { backgroundBlur }
        .overlay(alignment: .top) { cardOverlay }
        .overlay(alignment: .bottomLeading) { collapsedInfo }
        .overlay(alignment: .bottomTrailing) { inviteButtonReplica }
        .coordinateSpace(name: Self.imageSpace)
    }
}

//State-driven page geometry: ProfileCard's uniform edge-to-edge clip collapsed, the
//settled card's concentric top / sm bottom with the 3pt inset expanded. The values flip
//with `expanded` and interpolate inside the flight transaction (clip radii and padding
//are animatable).
extension InviteImageCarousel {

    private var inset: CGFloat { expanded ? Self.imagePadding : 0 }

    private var topRadius: CGFloat {
        expanded ? CornerRadius.concentric(in: CornerRadius.image, inset: Self.imagePadding) : CornerRadius.image
    }

    private var bottomRadius: CGFloat { expanded ? CornerRadius.sm : CornerRadius.image }
}

//Expanded chrome: fades in with the open flight, out with the close.
extension InviteImageCarousel {

    private var cardOverlay: some View {
        HStack {
            nameOverlay.opacityPop(visible: expanded)
            Spacer()
            optionsMenu
        }
        .padding(.vertical, Self.nameTopInset)
        .padding(.horizontal, Self.nameLeadingInset)
    }

    //Two Texts (not one string) so the halo mask hugs each word separately.
    private var nameOverlay: some View {
        HStack(spacing: Spacing.hairline) {
            Text("Meet")
                .getRect($meetFrame, coordSpace: Self.imageSpace)
            Text(name)
                .getRect($nameFrame, coordSpace: Self.imageSpace)
        }
        .font(.title(26))
        .foregroundStyle(Color.white)
    }

    private var optionsMenu: some View {
        Menu {
            if vm.event.hasChanges {
                Button("Clear Draft", systemImage: "trash", role: .destructive) {
                    withAnimation(.transition) { vm.deleteEventDefault() }
                }
            }
            Button("How Invites Work", systemImage: "info.circle") {
                showInfoScreen = true
            }
        } label: {
            InviteOptionsIcon()
                .padding(Spacing.xs)
                .shrinkPress()
                .contentShape(Circle())
        }
        .padding(-Spacing.xs)
        .blurPop(visible: optionsVisible)
        .sheet(isPresented: $showInfoScreen) { Text("Info screen here") }
    }

    private var pageIndicator: some View {
        AnimatedPageIndicator(count: images.count, progress: scrollProgress)
            .scaleEffect(0.7)
            .offset(y: 12) //Geometry: straddles the image's bottom edge
            .opacity(expanded ? 1 : 0)
    }

    //Cross-fades the two neighbouring pages' halos so the blur tracks the scroll progressively.
    //While a close cover is up the pager has already snapped to page 0, so the halo must
    //blur the cover — the page actually showing — not the page underneath it.
    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(images.count - 1))
        let page = Int(progress)
        let next = min(page + 1, images.count - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: coverImage ?? images[page], frames: [nameFrame, meetFrame])
                .opacity(1 - fraction)
            if coverImage == nil && next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, meetFrame])
                    .opacity(fraction)
            }
        }
        .opacity(expanded ? 1 : 0)
    }
}

//Collapsed chrome: ProfileCard's overlay, fading/blurring out in place as the card opens.
//Always present (never inserted mid-animation) so the close lands back on ProfileCard's
//exact rendering.
extension InviteImageCarousel {

    private var collapsedInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(name)
                .font(.title(26))
            Text(details)
                .font(.body(14, .medium))
        }
        .foregroundStyle(Color.white)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal)
        .opacity(expanded ? 0 : 1)
        .blur(radius: expanded ? 6 : 0)
        .allowsHitTesting(false)
    }

    //Decorative copy of ProfileCard's invite button: the tap that opened the invite covered
    //the real button mid-press, so the replica starts at the pressed scale and plays the
    //release bounce on mount. On expand it fades out in place; taps land on SendInviteCard's
    //reopen target, never here.
    private var inviteButtonReplica: some View {
        InviteButton(isInviting: true, action: {})
            .scaleEffect(inviteButtonPopped ? 1 : PressEffect.shrink.scale)
            .opacityPop(visible: !expanded)
            .padding([.trailing, .bottom], Spacing.md)
            .allowsHitTesting(false)
            .task {
                withAnimation(.spring(response: PressEffect.shrink.release.response,
                                      dampingFraction: PressEffect.shrink.release.damping)) {
                    inviteButtonPopped = true
                }
            }
    }

    //Always present (never inserted mid-animation): opaque only while a close carries a
    //non-first page home; fades out riding `expanded` to reveal the snapped-to page 0.
    private var closeCover: some View {
        Color.clear
            .overlay {
                Image(uiImage: coverImage ?? images[0])
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(
                topLeadingRadius: topRadius, bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius, topTrailingRadius: topRadius))
            .padding(.horizontal, inset)
            .padding(.top, inset)
            .opacity(coverImage != nil && expanded ? 1 : 0)
            .allowsHitTesting(false)
    }
}
