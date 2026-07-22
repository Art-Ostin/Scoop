//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//A single, screen-inset app image. Carousel page geometry lives in ScoopImageCarousel.
struct ScoopImage: View {
    let image: UIImage

    var aspectRatio: AspectRatio = .default
    var cornerRadius: CGFloat = CornerRadius.image
    var zoomSourceID: String? = nil //UIKit-backs the image so ImageZoom can fly a screen out of it

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio.ratio, contentMode: .fit)
            .overlay { imageContent }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .containerRelativeFrame(.horizontal) { length, _ in
                guard length.isFinite else { return 0 }
                return max(length - Spacing.gutter * 2, 0)
            }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let zoomSourceID {
            ZoomSourceImage(id: zoomSourceID, image: image, cornerRadius: cornerRadius)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
    }
}

struct ScoopImageCarousel: View {
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
        let base = carouselImage(image)
        if let onImageTap {
            base.contentShape(Rectangle()).onTapGesture { onImageTap(index) }
        } else {
            base
        }
    }

    private func carouselImage(_ image: UIImage) -> some View {
        carouselImageBase
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadii: .init(top: topRadius, bottom: bottomRadius)))
            .padding(.horizontal, hPadding)
            .containerRelativeFrame(.horizontal) { length, _ in
                length.isFinite ? length : 0
            }
    }

    @ViewBuilder
    private var carouselImageBase: some View {
        if fillsContainerHeight {
            Color.clear
        } else {
            Color.clear.aspectRatio(aspectRatio.ratio, contentMode: .fit)
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
            ScoopImageCarousel(
                images: images,
                hPadding: imagePadding,
                topRadius: topRadius,
                bottomRadius: CornerRadius.sm,
                aspectRatio: AspectRatio.card,
                scrollProgress: $scrollProgress,
                scrollPosition: .constant(ScrollPosition())
            )
            .overlay(alignment: .bottom) {
                ImagePageIndicator(count: images.count, progress: scrollProgress)
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
