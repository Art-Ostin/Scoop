//
//  ImageScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.

import SwiftUI

struct ImageCarousel: View {
    let images: [UIImage]

    // Geometry
    let hPadding: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    var aspectRatio: AspectRatio = .default

    @Binding var scrollProgress: Double
    @Binding var scrollPosition: ScrollPosition
    var hiddenIndex: Int? //Page hidden while a morph's floating copy covers it

    init(
        images: [UIImage],
        hPadding: CGFloat,
        topRadius: CGFloat,
        bottomRadius: CGFloat,
        aspectRatio: AspectRatio = .default,
        scrollProgress: Binding<Double> = .constant(0),
        scrollPosition: Binding<ScrollPosition> = .constant(ScrollPosition()),
        hiddenIndex: Int? = nil
    ) {
        self.images = images
        self.hPadding = hPadding
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
        self.aspectRatio = aspectRatio
        self._scrollProgress = scrollProgress
        self._scrollPosition = scrollPosition
        self.hiddenIndex = hiddenIndex
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(images.indices, id: \.self) { index in
                    carouselImage(images[index])
                        .opacity(index == hiddenIndex ? 0 : 1)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        .trackScrollProgress(scrollProgress: $scrollProgress)
        .scrollClipDisabled() //Pages bleed past the gutter mid-scroll; the parent card mask cuts them
    }

    private func carouselImage(_ image: UIImage) -> some View {
        ScoopImage(
            image: image,
            aspectRatio: aspectRatio,
            radius: topRadius,
            bottomRadius: bottomRadius,
            hPadding: hPadding,
            isCarousel: true
        )
    }
}



struct CardImageScrollView: View {

    //Standardised card-image geometry. SendInviteCard derives its card/flight radii
    //from these so the flight copy always matches the settled carousel.
    static let imagePadding: CGFloat = 3
    static let parentCornerRadius = CornerRadius.image
    static let aspectRatio: AspectRatio = .card
    static let bottomRadius = CornerRadius.sm //Card content continues below the image
    static var topRadius: CGFloat { CornerRadius.concentric(in: parentCornerRadius, inset: imagePadding) }

    //Injected (scrollProgress: pass a binding when the parent tracks paging, e.g. InviteImageCarousel's blur)
    let images: [UIImage]
    var scrollProgress: Binding<Double>? = nil

    //Local view state
    @State private var internalProgress: Double = 0

    private var progress: Binding<Double> { scrollProgress ?? $internalProgress }

    var body: some View {
        VStack(spacing: 8) {
            ImageCarousel(
                images: images,
                hPadding: Self.imagePadding,
                topRadius: Self.topRadius,
                bottomRadius: Self.bottomRadius,
                aspectRatio: Self.aspectRatio,
                scrollProgress: progress
            )

            AnimatedPageIndicator(count: images.count, progress: progress.wrappedValue)
                .scaleEffect(0.7, anchor: .top)
        }
        .padding(.top, Self.imagePadding) //Horizontal padding applied inside ImageCarousel
    }
}





//Free-page pager. Still used by RespondContainer; ImageCarousel replaces it for image paging.
struct HorizontalScrollView<Content: View>: View {
    var peek: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                content
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }
}

extension View {
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
