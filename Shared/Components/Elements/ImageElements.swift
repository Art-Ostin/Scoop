//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//All App Images differ on 4 points: (1) Aspect Ratio (2) HPadding (3) corner Radius (4) Shadow. Standardised here
struct ScoopImage: View {
    let image: UIImage

    var aspectRatio: AspectRatio = .default
    var radii: RectangleCornerRadii = .init(uniform: CornerRadius.image)
    var hPadding: CGFloat = Spacing.gutter

    var fillsPageWidth = false
    var showShadow = false

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
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
            .cardShadow(showShadow: showShadow)
    }
}


struct ImageCarousel: View {
    let images: [UIImage]

    // Geometry
    let hPadding: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    var aspectRatio: AspectRatio

    @Binding var scrollProgress: Double
    @Binding var scrollPosition: ScrollPosition
    var hiddenIndex: Int? = nil //Page hidden while the profile-morph flight copy covers it

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
        .pagedScroll(progress: $scrollProgress)
        .scrollPosition($scrollPosition)
        .scrollClipDisabled() //Pages bleed past the gutter mid-scroll; the parent card mask cuts them
    }

    private func carouselImage(_ image: UIImage) -> some View {
        ScoopImage(
            image: image,
            aspectRatio: aspectRatio,
            radii: .init(top: topRadius, bottom: bottomRadius),
            hPadding: hPadding,
            fillsPageWidth: true
        )
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
