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

    static let cardRadius: CGFloat = 24
    static let screenGap: CGFloat = 10
    static let imagePadding: CGFloat = 3
    static var imageRadius: CGFloat { cardRadius - imagePadding }
    static let imageBottomRadius: CGFloat = 12
    static let sourceRadius: CGFloat = 20 //Profile card image clip radius (collapsed state)
    static let imageHeightRatio: CGFloat = 1.05
    static let nameBlurInset: CGFloat = 10
    static let chromeBottomPadding: CGFloat = 16 //Shared by flight and carousel — if they differ the settle handoff snaps
    //Declared on ProfileCard's root: every frame here is measured in it, so the whole
    //morph is anchored to the feed cell and rides the scroll instead of the screen.
    static let cellSpace = "SendInviteCard.cell"

    @State var vm: TimeAndPlaceViewModel

    let image: UIImage
    let images: [UIImage]
    let details: String
    @Binding var expanded: Bool
    let sourceFrame: CGRect //Collapsed ProfileCard footprint in cell space; the flight departs from and returns to it
    var showsHideButton: Bool = true //Hide pill on the expanded image; the invite button morphs into it
    let onExpand: () -> Void //Joins the open transaction — the feed scrolls this card to the top on the same spring
    let hideInvite: () -> Void
    let sendInvite: (EventFieldsDraft) -> Void

    @State private var cellWidth: CGFloat = 0
    @State private var cardFrame: CGRect = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var hasOpened = false
    @State private var settled = false //True once the open flight lands; swaps the flight copy for the live carousel
    @State private var scrollProgress: Double = 0

    private var gallery: [UIImage] { images.isEmpty ? [image] : images }

    var body: some View {
        ZStack(alignment: .top) {
            cardBackground
            cardContent(imageWidth: cellWidth - 2 * (Self.screenGap + Self.imagePadding))
            flight
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cellWidth = $0 }
        //The card's slot in the feed: the ProfileCard footprint when collapsed, the full card once
        //expanded. Animating this height moves the feed apart in lockstep with the mask reveal.
        .frame(height: slotHeight, alignment: .top)
        .onChange(of: expanded) { _, isExpanded in expandedChanged(isExpanded) }
    }
}

//Card layout
extension SendInviteCard {

    //Pre-measure (cell recycled back on screen mid-invite) falls back to natural height — no snap.
    private var slotHeight: CGFloat? {
        guard expanded else { return sourceFrame.height }
        return cardFrame.height > 1 ? cardFrame.height : nil
    }

    private func cardContent(imageWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            imageSlot(imageWidth)
            pageIndicator
                .scaleEffect(0.7, anchor: .top)
            sendInviteContainer
        }
        .padding([.horizontal, .top], Self.imagePadding)
        .padding(.bottom, 12)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.cellSpace)) } action: {
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
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.cellSpace)) } action: {
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
            onHide: hideInvite
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
            onSendInvite: { sendInvite(vm.event) }
        )
    }
}

//Flight copy + expanding background
extension SendInviteCard {

    private var flight: some View {
        SendInviteFlight(
            image: image,
            name: vm.inviteModel.name,
            details: details,
            rect: expanded ? imageFrame : sourceFrame,
            expanded: $expanded,
            settled: settled,
            showsHideButton: showsHideButton,
            hideInvite: hideInvite
        )
    }

    private var cardBackground: some View {
        backgroundShape(.zero)
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

extension SendInviteCard {

    private func openWhenMeasured() {
        guard !hasOpened, imageFrame.height > 50, cardFrame.height > 50 else { return }
        hasOpened = true
        //Cell recycled and remounted while already expanded: adopt the settled state, no flight.
        if expanded {
            settled = true
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(sourceFrame.width > 1 ? Self.openFlight : nil, completionCriteria: .removed) {
                expanded = true
                onExpand()
            } completion: {
                settled = expanded
            }
        }
    }

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
