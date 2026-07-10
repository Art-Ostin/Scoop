//
//  ImageScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.

import SwiftUI

struct CardImageScrollView: View {
    //Card geometry, static so SendInviteCard's flight radii always match the settled carousel.
    static let parentCornerRadius: CGFloat = CornerRadius.image
    static let imagePadding: CGFloat = 3
    static let bottomRadius: CGFloat = CornerRadius.sm
    static var topRadius: CGFloat { CornerRadius.concentric(in: parentCornerRadius, inset: imagePadding) }

    let images: [UIImage]

    //Scroll progress passed up as parent tracks paging InviteImageCarousel blur
    @Binding var scrollProgress: Double

    var body: some View {
        VStack(spacing: 8) {
            ImageCarousel(
                images: images,
                hPadding: Self.imagePadding,
                topRadius: Self.topRadius,
                bottomRadius: Self.bottomRadius,
                aspectRatio: AspectRatio.card,
                scrollProgress: $scrollProgress,
                scrollPosition: .constant(ScrollPosition())
            )
            .overlay(alignment: .bottom) {
                AnimatedPageIndicator(count: images.count, progress: scrollProgress)
                    .scaleEffect(0.7, anchor: .top)
                    .offset(y: 12)
            }
            .padding(.top, Self.imagePadding)
        }
    }
}


extension View {
    //Shared pager defaults. .paging over .viewAligned is deliberate: viewAligned settles too soft.
    //Position tracking and clip behaviour vary per pager, so they stay at the call site.
    @ViewBuilder
    func horizontalScrollSlot(id: some Hashable, shrinkAnchor: UnitPoint? = nil) -> some View {
        let page = self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerRelativeFrame(.horizontal)
            .id(id)

        if let shrinkAnchor {
            page.pageScrollTransition(anchor: shrinkAnchor)
        } else {
            page
        }
    }

    func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat = 0) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            let progress = 1 - min(abs(phase.value), 1)
            let scale = 0.5 + progress * 0.5
            return content
                .scaleEffect(scale, anchor: anchor)
                .offset(y: (1 - progress) * yOffset)
        }
    }
}
