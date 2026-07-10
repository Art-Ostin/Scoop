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

    var hPadding: CGFloat = 16
    var radius: CGFloat = CornerRadius.image
    var bottomRadius: CGFloat? = nil //nil = match radius
    var showShadow = false
    var aspectRatio: AspectRatio = .default
    var isCarousel = false
    
    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .imageClip(top: radius, bottom: bottomRadius ?? radius)
            .imagePadding(isCarousel, hPadding: hPadding)
            .cardShadow(showShadow: showShadow)
    }
}

extension View {
    func imagePadding(_ isCarousel: Bool, hPadding: CGFloat) -> some View {
        padding(.horizontal, isCarousel ? hPadding : 0)
        .containerRelativeFrame(.horizontal) { length, _ in
            isCarousel ? length : length - hPadding * 2
        }
    }
    
    func imageClip(_ radius: CGFloat = CornerRadius.image) -> some View {
        imageClip(top: radius, bottom: radius)
    }

    func imageClip(top: CGFloat, bottom: CGFloat) -> some View {
        clipShape(.rect(
            topLeadingRadius: top,
            bottomLeadingRadius: bottom,
            bottomTrailingRadius: bottom,
            topTrailingRadius: top,
            style: .continuous
        ))
    }
}

struct SmallPhoto: View {
    
    let image: UIImage
    let size: CGFloat
    var radius: CGFloat = CornerRadius.thumb
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
