//
//  InviteMorphBackground.swift
//  Scoop Test
//
//  Created by Art Ostin on 01/07/2026.
//

import SwiftUI
import DominantColors
import Glur

struct InviteMorphBackground: View {
    let expanded: Bool
    let image: UIImage
    // Extracted once by the parent morph and shared with the card; `.clear` until it lands.
    let tint: Color


    var body: some View {

        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
                .opacity(expanded ? 1 : 0)
                .allowsHitTesting(expanded) // dismiss is Hide-only

            Group {
                tint
                    .opacity(0.3)
                appImageOverlay
            }
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.4), value: tint)
    }
}


//Image Card
extension InviteMorphBackground {
    
    private var appImageOverlay: some View {
        Color.clear
            .aspectRatio(1/1.5, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .glur(radius: 25,
                          offset: 0.7,
                          interpolation: 0.6,
                          direction: .down
                    )
            }
            .clipShape(.rect(cornerRadius: 0, style: .continuous))
            .mask { blurEdgeGradient}
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .offset(y: -36)
            .overlay(alignment: .bottom) {
                linearGradientOverlay
            } //Has nice effect putting overlay here
    }
    
    private var linearGradientOverlay: some View{
        LinearGradient(
            stops: [
                .init(color: tint.opacity(0.0),  location: 0.0),
                .init(color: tint.opacity(0.0),  location: 0.7),  // stay clear across the photo
                .init(color: tint.opacity(0.15), location: 0.88),
                .init(color: tint.opacity(0.25), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
    
    
    private var blurEdgeGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.75),  // matches glur's offset
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}


//Logic for Background
extension InviteMorphBackground {

    nonisolated static func backgroundTint(from image: UIImage) async -> Color {
        let raw = try? DominantColors.dominantColors(
            uiImage: image,            // ← RAW image (no canonicalRGBA yet) to reproduce the green
            quality: .high,
            options: [.excludeBlack, .excludeWhite, .excludeGray]
        ).first
        guard let dominant = raw else { return .clear }
        return Color(dominant.normalizedForBackground())
    }
}


import UIKit

extension UIColor {
    /// Pull the extracted color into a legible band: never neon, never washed out,
    /// dark enough for white text to sit on top.
    func normalizedForBackground() -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        s = min(max(s, 0.35), 0.70)   // clamp saturation
        b = min(max(b, 0.35), 0.55)   // clamp brightness
        return UIColor(hue: h, saturation: s, brightness: b, alpha: 1)
    }
}

/*
 struct InviteMorphBackground: View {

     let expanded: Bool

     var body: some View {
         Rectangle()
             .fill(.ultraThinMaterial)
             .ignoresSafeArea()
             .opacity(expanded ? 1 : 0)
             .allowsHitTesting(expanded) // dismiss is Hide-only
     }
 }

 
 */
