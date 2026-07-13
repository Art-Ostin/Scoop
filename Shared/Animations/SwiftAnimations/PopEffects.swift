//
//  PopEffects.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2026.
//

import SwiftUI


private struct OpacityPop: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(visible ? 1 : shrunkScale)
            .opacity(visible ? 1 : 0)
    }
}

extension View {
    func opacityPop(visible: Bool, scale: CGFloat = 0.4) -> some View {
        modifier(OpacityPop(visible: visible, shrunkScale: scale))
    }
}

private struct BlurPop: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat
    var blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: visible ? 0 : blurRadius)
            .scaleEffect(visible ? 1 : shrunkScale)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible) //Stays mounted while hidden, so gate taps
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: visible)
    }
}

extension View {
    func blurPop(visible: Bool, scale: CGFloat = 0.7, blur: CGFloat = 8) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur))
    }
}
