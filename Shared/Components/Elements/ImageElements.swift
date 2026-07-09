//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//Expands full width of view, and height set proportional
struct GreedyImage: View {

    let image: UIImage
    let hPadding: CGFloat
    var aspectRatio: AspectRatio = .card


    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .padding(.horizontal, hPadding)
            .containerRelativeFrame(.horizontal)
    }
}

//Profile image carousel at top of a card
struct CardImageScrollView: View {

    //Standardised card-image geometry. SendInviteCard derives its card/flight radii
    //from these so the flight copy always matches the settled carousel.
    static let imagePadding: CGFloat = 3
    static let parentCornerRadius = CornerRadius.photoCard
    static let aspectRatio: AspectRatio = .card
    static let bottomRadius = CornerRadius.sm //Card content continues below the image
    static var topRadius: CGFloat { CornerRadius.nested(in: parentCornerRadius, inset: imagePadding) }

    let images: [UIImage]
    @Binding var scrollProgress: Double

    var body: some View {
        VStack(spacing: 8) {
            ImageCarousel(
                images: images,
                hPadding: Self.imagePadding,
                topRadius: Self.topRadius,
                bottomRadius: Self.bottomRadius,
                aspectRatio: Self.aspectRatio,
                scrollProgress: $scrollProgress
            )
            AnimatedPageIndicator(count: images.count, progress: scrollProgress)
                .scaleEffect(0.7, anchor: .top)
        }
        .padding(.top, Self.imagePadding) //Horizontal padding applied inside ImageCarousel
    }
}
