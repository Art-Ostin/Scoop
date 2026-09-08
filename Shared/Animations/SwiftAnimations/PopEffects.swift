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

    ///`opacityPop`'s own shrunk pose, named because the event zoom wears it in two places at once: a
    ///copy of the band's chrome pops in on the flying cover, driven off the flight's p, while the real
    ///piece waits underneath. They have to meet on identical pixels at the cover's cut, so a literal
    ///in either place is a seam waiting to open.
    static let opacityShrunkScale: CGFloat = 0.4
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

//The same pose as `blurPop`, but as one phase of a transition — no curve and no hit-test gate of its
//own, because a transitioning view is unmounted rather than hidden. The caller's transaction times it.
private struct BlurPopPhase: ViewModifier {
    var visible: Bool
    var shrunkScale: CGFloat
    var blurRadius: CGFloat
    var anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .blur(radius: visible ? 0 : blurRadius)
            .scaleEffect(visible ? 1 : shrunkScale, anchor: anchor)
            .opacity(visible ? 1 : 0)
    }
}

extension View {
    
    func opacityPop(visible: Bool, scale: CGFloat = PopMotion.opacityShrunkScale, anchor: UnitPoint = .center) -> some View {
        modifier(OpacityPop(visible: visible, shrunkScale: scale, anchor: anchor))
    }
    
    //Same edge rule as opacityPop: pinned chrome shrinks toward its edge, or it slides as it blurs
    func blurPop(visible: Bool, scale: CGFloat = PopMotion.shrunkScale,
                 blur: CGFloat = PopMotion.blurRadius, anchor: UnitPoint = .center) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur, anchor: anchor))
    }
}

extension AnyTransition {

    ///`blurPop` for content that must leave the LAYOUT as it goes, so its neighbours close the gap
    ///behind it — a word dropping out of a line and the words after it sliding along.
    static func blurPop(scale: CGFloat = PopMotion.shrunkScale,
                        blur: CGFloat = PopMotion.blurRadius,
                        anchor: UnitPoint = .center) -> AnyTransition {
        .modifier(
            active: BlurPopPhase(visible: false, shrunkScale: scale, blurRadius: blur, anchor: anchor),
            identity: BlurPopPhase(visible: true, shrunkScale: scale, blurRadius: blur, anchor: anchor))
    }
}
