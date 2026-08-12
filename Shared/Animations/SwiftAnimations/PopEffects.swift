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
    var anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(visible ? 1 : shrunkScale, anchor: anchor)
            .opacity(visible ? 1 : 0)
    }
}

extension View {
    //An edge-pinned view has to shrink toward the edge it's pinned to, or it slides as it fades
    func opacityPop(visible: Bool, scale: CGFloat = 0.4, anchor: UnitPoint = .center) -> some View {
        modifier(OpacityPop(visible: visible, shrunkScale: scale, anchor: anchor))
    }
}

private struct BlurPop: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat
    var blurRadius: CGFloat
    var anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .blur(radius: visible ? 0 : blurRadius)
            .scaleEffect(visible ? 1 : shrunkScale, anchor: anchor)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible) //Stays mounted while hidden, so gate taps
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: visible)
    }
}

extension View {
    //Same edge rule as opacityPop: pinned chrome shrinks toward its edge, or it slides as it blurs
    func blurPop(visible: Bool, scale: CGFloat = 0.7, blur: CGFloat = 8, anchor: UnitPoint = .center) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur, anchor: anchor))
    }
}
