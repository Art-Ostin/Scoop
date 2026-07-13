//
//  PopEffects.swift
//  Scoop
//
//  Created by Art Ostin on 24/06/2026.
//

import SwiftUI


// MARK:  Default show / dismiss animation
extension Animation {
    static let scoopPop: Animation = .spring(response: 0.35, dampingFraction: 0.7)
}

extension AnyTransition {
    static var scoopPop: AnyTransition {
        AnyTransition(.blurReplace).combined(with: .scale(scale: 0.8, anchor: .top))
    }
}


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
            .animation(.scoopPop, value: visible)
    }
}

extension View {
    func blurPop(visible: Bool, scale: CGFloat = 0.7, blur: CGFloat = 8) -> some View {
        modifier(BlurPop(visible: visible, shrunkScale: scale, blurRadius: blur))
    }
}
