//
//  SendInviteCard.swift
//  Scoop
//
//  Created by Art Ostin on 07/07/2026.
//

import SwiftUI

struct SendInviteCard: View {

    static let openFlight = Animation.smooth(duration: 0.3)
    static let closeFlight = Animation.smooth(duration: 0.28)

    //Concentric geometry: the image sits `imagePadding` inside the card, so its radius derives from the card's.
    static let cardRadius: CGFloat = 24
    static let screenGap: CGFloat = 10
    static let imagePadding: CGFloat = 3
    static var imageRadius: CGFloat { cardRadius - imagePadding }
    static let imageBottomRadius: CGFloat = 12
    static let sourceRadius: CGFloat = 20 //Profile card image clip radius (collapsed state)
    static let imageHeightRatio: CGFloat = 1.05
    static let nameBlurInset: CGFloat = 10
    static let chromeBottomPadding: CGFloat = 16 //Shared by flight and carousel — if they differ the settle handoff snaps

    @State var vm: TimeAndPlaceViewModel

    let image: UIImage
    let images: [UIImage]
    let details: String
    @Binding var expanded: Bool
    let sourceFrame: CGRect //Profile card image frame, global coords
    var showsHideButton: Bool = true //Hide pill on the expanded image; the invite button morphs into it
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void

    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var hasOpened = false
    @State private var settled = false //True once the open flight lands; swaps the flight copy for the live carousel
    @State private var scrollProgress: Double = 0

    private var gallery: [UIImage] { images.isEmpty ? [image] : images }

    var body: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            ZStack(alignment: .top) {
                cardBackground(origin)
                VStack(spacing: 0) {
                    cardContent(imageWidth: geo.size.width - 2 * (Self.screenGap + Self.imagePadding))
                    backButton
                }
                flight(origin)
            }
            .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
        }
    }
}

//Card layout
extension SendInviteCard {

    private func cardContent(imageWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            imageSlot(imageWidth)
            pageIndicator
                .scaleEffect(0.7, anchor: .top)
            sendInviteContainer
        }
        .padding([.horizontal, .top], Self.imagePadding)
        .padding(.bottom, 12)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
            cardFrame = $0
            openWhenMeasured()
        }
        .opacity(cardFrame.height > 1 ? 1 : 0) //Nothing shows until measured
        .mask { backgroundShape(cardFrame.origin) } //Revealed by the expanding background
        .allowsHitTesting(expanded)
        .padding(.horizontal, Self.screenGap)
    }

    private func imageSlot(_ width: CGFloat) -> some View {
        Color.clear
            .frame(width: max(width, 0), height: max(width, 0) * Self.imageHeightRatio)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                imageFrame = $0
                openWhenMeasured()
            }
            .overlay { carousel(max(width, 0)) }
    }

    //Page one sits exactly under the flight copy, so the settled swap never shows.
    private func carousel(_ width: CGFloat) -> some View {
        InviteImageCarousel(
            images: gallery,
            name: vm.inviteModel.name,
            size: CGSize(width: width, height: width * Self.imageHeightRatio),
            showsHideButton: showsHideButton,
            scrollProgress: $scrollProgress,
            onBack: hideInvite
        )
        .opacity(settled ? 1 : 0)
        .allowsHitTesting(settled)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if gallery.count > 1 {
            AnimatedPageIndicator(count: gallery.count, progress: scrollProgress)
                .frame(height: 0)
                .offset(y: 11)
        }
    }

    private var sendInviteContainer: some View {
        SendInviteContainer(
            draft: $vm.event,
            name: vm.inviteModel.name,
            isInviteResponse: false,
            defaults: vm.defaults,
            onClearDraft: { vm.deleteEventDefault() },
            hideInvite: hideInvite,
            onSendInvite: { sendInvite(vm.event) }
        )
    }

    private var backButton: some View {
        InviteBackButton(action: hideInvite)
            .opacityPop(visible: expanded)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Self.screenGap)
            .allowsHitTesting(settled)
            .padding(.top, 32)
    }
}

//Flight copy + expanding background
extension SendInviteCard {

    private func flight(_ origin: CGPoint) -> some View {
        SendInviteFlight(
            image: image,
            name: vm.inviteModel.name,
            details: details,
            rect: local(expanded ? imageFrame : sourceFrame, origin),
            expanded: $expanded,
            settled: settled,
            showsHideButton: showsHideButton,
            hideInvite: hideInvite
        )
    }

    private func cardBackground(_ origin: CGPoint) -> some View {
        backgroundShape(origin)
            .shadow(color: .black.opacity(expanded ? 0.05 : 0), radius: 3, x: 0, y: 1)
            .shadow(color: .black.opacity(expanded ? 0.04 : 0), radius: 20, x: 0, y: 0)
            .allowsHitTesting(false)
    }

    //Shared by the background and the content mask, so rows slide out from exactly under the traveling image.
    private func backgroundShape(_ origin: CGPoint) -> some View {
        let rect = local(expanded ? cardFrame : sourceFrame, origin)
        return RoundedRectangle(cornerRadius: expanded ? Self.cardRadius : Self.sourceRadius, style: .continuous)
            .fill(Color.appCanvas)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    private func local(_ rect: CGRect, _ origin: CGPoint) -> CGRect {
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
    }
}

//Open/settle state machine
extension SendInviteCard {

    //Opens only once both frames are measured AND a collapsed frame has rendered: the 30ms sleep
    //crosses a real frame boundary (a bare MainActor hop runs before the CA commit and the card snaps).
    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            //.removed: the settle swap must wait for the spring's true end, not its perceptual duration.
            withAnimation(sourceFrame.width > 1 ? Self.openFlight : nil, completionCriteria: .removed) {
                expanded = true
            } completion: {
                settled = expanded
            }
        }
    }

    //A reopen mid-close retargets the spring from MeetContainer (no completion reaches us),
    //so re-settle on a timer sized past the spring's full removal.
    private func expandedChanged(_ isExpanded: Bool) {
        if isExpanded {
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                if expanded { settled = true }
            }
        } else {
            settled = false
        }
    }
}
