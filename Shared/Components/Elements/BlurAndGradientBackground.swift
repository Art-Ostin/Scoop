//
//  BlurAndGradientBackground.swift
//  Scoop Test
//
//  Created by Art Ostin on 06/08/2026.
//

import SwiftUI

struct BlurAndGradientBackground: ViewModifier {
    
    // The fraction of the image height the modifications are applied to. I.E. 0.2 Blur and colour fade start 80% down the image
    let textRegion: CGFloat
    var blurRadius: CGFloat = 24

    //Blur starts below the text Region, and the blur Ramp is based on where it starts
    private var blurStart: CGFloat { 1 - textRegion * 0.825 }
    private var blurRamp: CGFloat { textRegion * 0.8 }

    //The Overlay Color
    let colour: Color
    
    //How dark the color over the text should be - varies for ensuring text legibility
    let scrimOpacity: CGFloat
    
    //Outlines the bottom area, to meausure it is bright enough and adjust luminosity accordingly
    static let inviteRegion: CGFloat = 0.4   //1:1.5 art under a whole confirm block
    static let profileRegion: CGFloat = 0.28 //1:1.2 art under two lines — starts lower, at 0.72
    
    func body(content: Content) -> some View {
        content
            .glur(
                radius: blurRadius,
                offset: blurStart,
                interpolation: blurRamp,
                direction: .down,
                noise: 0
            )
            .overlay { scrimGradient }
            .clipShape(.rect(cornerRadii: .init(top: 0, bottom: CornerRadius.image)))
    }
    
    //Hand-tuned ramp through the region, reaching the solved veil at the bottom edge
    private var scrimGradient: some View {
        let region = textRegion
        let top = 1 - region

        //Measures top of Colour based of blur
        return LinearGradient(
            stops: [
                .init(color: colour.opacity(0),           location: top),
                .init(color: colour.opacity(scrimOpacity * 0.67), location: top + region * 0.5),
                .init(color: colour.opacity(scrimOpacity * 0.78), location: top + region * 0.625),
                .init(color: colour.opacity(scrimOpacity),        location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
