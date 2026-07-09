//
//  GreedyImage.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//Expands full width of view, and height set proportional
struct GreedyImage: View {

    var aspectRatio: CGFloat = 1/1.05
    
    let image: UIImage
    
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
    }
}

//Profile image carousel at top of a card. Used in 'InviteCard' and 'CountdownTime'
struct CardImageScrollView: View {

    @State var scrollProgress: Double = 0
    
    //Content
    let images: [UIImage]
    
    //Standardised parameters for image in card
    let imagePadding: CGFloat = 3
    let parentCornerRadius: CGFloat = 24
    let aspectRatio: CGFloat = 1/1.05
    let bottomRadius: CGFloat = 12
    var topRadius: CGFloat { parentCornerRadius - imagePadding} //Concentric Corners
    
    var body: some View {
        VStack(spacing: 8) {
            ImageCarousel(
                images: images,
                hPadding: imagePadding,
                topRadius: topRadius,
                bottomRadius: bottomRadius,
                aspectRatio: aspectRatio,
                scrollProgress: $scrollProgress,
            )
            
            AnimatedPageIndicator(count: images.count, progress: scrollProgress)
        }
    }
}
