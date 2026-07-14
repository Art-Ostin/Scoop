//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//All App Images differ on 4 points: (1) Aspect Ratio (2) HPadding (3) corner Radius (4) Shadow. Standardised here.
struct ScoopImage: View {
    let image: UIImage

    var aspectRatio: AspectRatio = .default
    var radii: RectangleCornerRadii = .init(uniform: CornerRadius.image)
    var hPadding: CGFloat = Spacing.gutter

    var fillsPageWidth = false
    var fillsContainerHeight = false //Height from the proposed container (animated slots), not the aspect ratio
    var showShadow = false

    var body: some View {
        base
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadii: radii))
            .padding(.horizontal, fillsPageWidth ? hPadding : 0)
            .containerRelativeFrame(.horizontal) { length, _ in
                fillsPageWidth ? length : length - hPadding * 2
            }
//            .shadow(showShadow ? .card : nil)
    }

    @ViewBuilder
    private var base: some View {
        if fillsContainerHeight {
            Color.clear
        } else {
            Color.clear.aspectRatio(aspectRatio.ratio, contentMode: .fit)
        }
    }
}

struct ImageCarousel: View {
    let images: [UIImage]

    // Geometry
    let hPadding: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    var aspectRatio: AspectRatio
    var fillsContainerHeight = false
    var showFade = true //Horizontal edge fade; off collapses the invite endpoint to a plain edge-to-edge image (matches ProfileCard)
    var onImageTap: ((Int) -> Void)? = nil //Opt-in per-page tap (profile pager → full-screen zoom viewer); nil elsewhere

    @Binding var scrollProgress: Double
    @Binding var scrollPosition: ScrollPosition

    var body: some View {
        PagerScrollView(progress: $scrollProgress) {
            ForEach(images.indices, id: \.self) { index in
                carouselImage(images[index], index: index)
            }
        }
        .scrollPosition($scrollPosition)
        .scrollClipDisabled() //Pages bleed past the gutter mid-scroll; the parent card mask cuts them]
        .customHorizontalScrollFade(width: 3, showFade: showFade, fromLeading: true)
        .customHorizontalScrollFade(width: 3, showFade: showFade, fromLeading: false)
    }

    @ViewBuilder
    private func carouselImage(_ image: UIImage, index: Int) -> some View {
        let base = ScoopImage(
            image: image,
            aspectRatio: aspectRatio,
            radii: .init(top: topRadius, bottom: bottomRadius),
            hPadding: hPadding,
            fillsPageWidth: true,
            fillsContainerHeight: fillsContainerHeight
        )
        if let onImageTap {
            base.contentShape(Rectangle()).onTapGesture { onImageTap(index) }
        } else {
            base
        }
    }
}

struct CardImageCarousel: View {
    let images: [UIImage]
    let imagePadding: CGFloat = 3
    
    var topRadius: CGFloat { CornerRadius.concentric(in: CornerRadius.image, inset: 3)}
    
    //Drives the built-in page indicator
    @Binding var scrollProgress: Double
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ImageCarousel(
                images: images,
                hPadding: imagePadding,
                topRadius: topRadius,
                bottomRadius: CornerRadius.sm,
                aspectRatio: AspectRatio.card,
                scrollProgress: $scrollProgress,
                scrollPosition: .constant(ScrollPosition())
            )
            .overlay(alignment: .bottom) {
                AnimatedPageIndicator(count: images.count, progress: scrollProgress)
                    .scaleEffect(0.7)
                    .offset(y: 12)
            }
            .padding(.top, imagePadding)
        }
    }
}

struct SmallImage: View {
    let image: UIImage
    let size: CGFloat
    
    var radius: CGFloat = CornerRadius.smallImage
    var isCircle: Bool = false
        
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(.rect(
                cornerRadius: isCircle ? size / 2 : radius,
                style: isCircle ? .circular : .continuous
            ))
    }
}
