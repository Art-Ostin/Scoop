//
//  ImageElements.swift
//  Scoop
//
//  Created by Art Ostin on 09/07/2026.
//

import SwiftUI

//The app-standard image: container width minus hPadding, height set by the aspect ratio.
//All App Images differ on 4 points: (1) Aspect Ratio (2) HPadding (3) corner Radius (4) Shadow
struct ScoopImage: View {

    let image: UIImage

    var hPadding: CGFloat = 16
    var radius: CGFloat = Corner.photoCard
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
