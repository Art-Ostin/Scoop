//
//  PopEffects.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2026.
//

import SwiftUI


enum PopMotion {
    static let shrunkScale: CGFloat = 0.7
    static let blurRadius: CGFloat = 8
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7)

    static let platterShrunkScale: CGFloat = 0.5
    static let lensCutoff: CGFloat = 0.6
}



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
            .animation(PopMotion.spring, value: visible)
    }
}

extension View {
    
    func opacityPop(visible: Bool, scale: CGFloat = 0.4, anchor: UnitPoint = .center) -> some View {
        modifier(OpacityPop(visible: visible, shrunkScale: scale, anchor: anchor))
    }
    
    //Same edge rule as opacityPop: pinned chrome shrinks toward its edge, or it slides as it blurs
    func blurPop(visible: Bool, scale: CGFloat = PopMotion.shrunkScale,
                 blur: CGFloat = PopMotion.blurRadius, anchor: UnitPoint = .center) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur, anchor: anchor))
    }
}
