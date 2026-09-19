//
//  BlurAndGradientBackground.swift
//  Scoop
//
//  Created by Art Ostin on 06/08/2026.
//

import SwiftUI

struct BlurAndGradientBackground: ViewModifier {
    
    // The fraction of the image height the modifications are applied to. I.E. 0.2 Blur and colour fade start 80% down the image
    let textRegion: CGFloat
    var blurRadius: CGFloat = 24
    var blurReach: CGFloat = 0.825 //How far up the text region the blur starts
    var colourRegion: CGFloat? = nil //Where the colour starts, when it should reach higher than the text region; nil = the text region's top. The blur never reads it

    //Blur starts below the text Region, and the blur Ramp is based on where it starts.
    //Internal, not private: the invite flight's blur band (ProfileCardChrome) renders the
    //same glur from this spec so the two can't drift apart.
    var blurStart: CGFloat { 1 - textRegion * blurReach }
    var blurRamp: CGFloat { textRegion * 0.8 }

    //The Overlay Color
    let colour: Color
    
    //How dark the color over the text should be - varies for ensuring text legibility
    let scrimOpacity: CGFloat
    
    //Outlines the bottom area, to meausure it is bright enough and adjust luminosity accordingly
    static let inviteRegion: CGFloat = 0.38 //Geometry: the invite card's name + two 18pt rows, its top ~127pt off the foot — what its blur is measured from
    static let inviteColourRegion: CGFloat = 0.4 //The invite card's colour reaches higher than its text, starting 60% down
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
    
    //Hand-tuned ramp through the region, reaching the solved veil at the bottom edge.
    //Internal, not private: ProfileCardChrome draws it as its own layer so the invite flight
    //can exit the veil separately from the blur band.
    var scrimGradient: some View {
        let region = colourRegion ?? textRegion
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
