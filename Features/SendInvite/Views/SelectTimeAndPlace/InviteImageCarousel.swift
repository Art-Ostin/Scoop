//
//  InviteImageCarousel.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

struct InviteImageCarousel: View {
    //Injected
    let images: [UIImage]
    let name: String
    let details: String
    let expanded: Bool
    @Binding var scrollProgress: Double
    @Binding var pagerPosition: ScrollPosition
    @Binding var confirmInviteScreen: Bool
    let coverImage: UIImage? //Close-from-page-N: the page flying home, over the snapped-to page 0 (see SendInviteCard.prepareClose)
    let vm: TimeAndPlaceViewModel //@Observable class — drives the options menu (clear draft)
    let declineProfile: () -> Void
    var pagingDisabled: Bool = false //Locked while the frame animates or a swipe-dismiss owns the touch
    var optionsVisible: Bool = true //Flips at drag release (not spring completion) so the menu pops back riding the spring-back
    var showsCollapsedChrome: Bool = true //The collapsed ProfileCard look (name/details caption + button replica). Off when the source is a plain image (profile hero).

    //Local view state
    @State private var inviteFrame: CGRect = .zero
    @State private var nameFrame: CGRect = .zero
    @State private var optionsFrame: CGRect = .zero
    
    @State private var inviteButtonPopped = false
    @State private var showInfoScreen = false //"How Invites Work" sheet, opened from the options menu

    private static let imageSpace = "InviteImageCarousel.image"
    //Name inset from the image edge (the halo mask measures against these)
    static let nameLeadingInset: CGFloat = 17
    static let nameTopInset: CGFloat = 12
    static let imagePadding: CGFloat = 0

    var body: some View {
        ScoopImageCarousel(
            images: images,
            hPadding: inset,
            topRadius: 0,
            bottomRadius: 0,
            aspectRatio: confirmInviteScreen ? .confirmInviteImage : .invitedImage,
            fillsContainerHeight: true, //The animated frame owns the height at both endpoints
            showFade: false,
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
//settled card's edge-to-edge top / square bottom expanded. The values flip
//with `expanded` and interpolate inside the flight transaction (clip radii and padding
//are animatable).
extension InviteImageCarousel {

    private var inset: CGFloat { expanded ? Self.imagePadding : 0 }

    private var topRadius: CGFloat {
        expanded ? CornerRadius.concentric(in: CornerRadius.image, inset: Self.imagePadding) : CornerRadius.image
    }

    private var bottomRadius: CGFloat { expanded ? 0 : CornerRadius.image }
}

//Expanded chrome: fades in with the open flight, out with the close.
extension InviteImageCarousel {

    private var cardOverlay: some View {
        HStack {
            leadingOverlay
            Spacer()
            optionsMenu
        }
        .padding(.vertical, Self.nameTopInset)
        .padding(.leading, confirmInviteScreen ? Self.nameTopInset : Self.nameLeadingInset)
        .padding(.trailing, Self.nameLeadingInset)
    }

    private var leadingOverlay: some View {
        nameOverlay
            .opacityPop(visible: expanded)
            .blurPop(visible: !confirmInviteScreen, scale: 0.9, blur: 6)
            .overlay(alignment: .leading) { confirmBackButton }
    }

    //Two Texts (not one string) so the halo mask hugs each word separately.
    private var nameOverlay: some View {
        HStack(spacing: 6) {
            Text("Invite")
                .getRect($inviteFrame, coordSpace: Self.imageSpace)

            Text(name)
                .getRect($nameFrame, coordSpace: Self.imageSpace)
        }
        .font(.title(24))
        .foregroundStyle(Color.white)
    }

    private var confirmBackButton: some View {
        ScoopButton(style: .clearGlass, shape: Circle(), action: {confirmInviteScreen = false}) {
            Image(systemName: "chevron.left")
                .font(.body(17))
                .fontWeight(.heavy)
                .foregroundStyle(Color.black)
                .frame(width: 38, height: 38)
        }
        .blurPop(visible: expanded && confirmInviteScreen)
    }

    private var optionsMenu: some View {
        Menu {
            Button("How Invites Work", systemImage: "info.circle") {
                showInfoScreen = true
            }
            if vm.event.hasChanges {
                Button {
                    withAnimation(.transition) {
                        vm.deleteEventDefault()
                    }
                } label: {
                    Label {
                        Text("Clear Invite Draft")
                    } icon: {
                        Image("BinIcon")
                            .renderingMode(.template)
                            .scaleEffect(1.2)
                    }
                }
            }

            Button(role: .destructive) {
                declineProfile()
            } label: {
                Label {
                    Text("Decline Profile")
                } icon: {
                    Image(systemName: "xmark")
                        .font(.body(14, .bold))
                }
            }
        } label: {
            optionsLabel
        }
        .padding(-Spacing.sm)
        .blurPop(visible: optionsVisible)
        .sheet(isPresented: $showInfoScreen) { Text("Info screen here") }
    }

    private var pageIndicator: some View {
        ImagePageIndicator(count: images.count, progress: scrollProgress, activeColor: .white)
            .scaleEffect(0.7)
            .padding(.bottom, Spacing.xs)
            .opacityPop(visible: !confirmInviteScreen)
    }

    private var backgroundBlur: some View {
        let progress = min(max(scrollProgress, 0), Double(images.count - 1))
        let page = Int(progress)
        let next = min(page + 1, images.count - 1)
        let fraction = progress - Double(page)

        return ZStack {
            BackgroundBlur(image: coverImage ?? images[page], frames: [nameFrame, inviteFrame, optionsFrame])
                .opacity(1 - fraction)
            if coverImage == nil && next != page && fraction > 0 {
                BackgroundBlur(image: images[next], frames: [nameFrame, inviteFrame, optionsFrame])
                    .opacity(fraction)
            }
        }
        .opacity(expanded && !confirmInviteScreen ? 1 : 0)
        .animation(.transition, value: confirmInviteScreen)
    }
    
    private var optionsLabel: some View {
        HStack(spacing: 4) {
            circle
            circle
            circle
        }
        .scaleEffect(0.95)
        .padding(2)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.04))
                .blur(radius: 2)
        }
        .getRect($optionsFrame, coordSpace: Self.imageSpace)
        .padding(Spacing.sm - 2)//Offset interior padding with capsule
        .growButton(shadow: .card)
        .contentShape(Circle())
        .offset(y: -2)//
    }
    
    private var circle: some View {
        Circle()
            .fill(.white.opacity(0.8))
            .frame(width: 4.5, height: 4.5)
    }
}

//Collapsed chrome: ProfileCard's overlay, fading/blurring out in place as the card opens.
//Always present (never inserted mid-animation) so the close lands back on ProfileCard's
//exact rendering.
extension InviteImageCarousel {

    @ViewBuilder
    private var collapsedInfo: some View {
        if showsCollapsedChrome {
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
    }

    @ViewBuilder
    private var inviteButtonReplica: some View {
        if showsCollapsedChrome {
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
    }

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
