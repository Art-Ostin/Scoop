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

//Shared so a pop that has to be split across the SwiftUI/UIKit seam — a toolbar item's label
//and the glass platter UIKit draws behind it — can't drift out of step. See `toolbarPlatter`.
enum PopMotion {
    static let shrunkScale: CGFloat = 0.7
    static let blurRadius: CGFloat = 8
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7)

    ///A bar item has no free-floating circle to lose, so it has to shrink harder than the
    ///overlay pop to read at all — most of the travel happens while it is already fading.
    static let platterShrunkScale: CGFloat = 0.5
    ///How much of the pop the platter's label gets before it is fully faded — the shrink runs on
    ///past it. Keeps the icon off the spring's long tail.
    static let lensCutoff: CGFloat = 0.6
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
    //Same edge rule as opacityPop: pinned chrome shrinks toward its edge, or it slides as it blurs
    func blurPop(visible: Bool, scale: CGFloat = PopMotion.shrunkScale,
                 blur: CGFloat = PopMotion.blurRadius, anchor: UnitPoint = .center) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur, anchor: anchor))
    }
}
