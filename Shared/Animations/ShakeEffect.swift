//
//  ShakeEffect.swift
//  Scoop
//
//  Created by Art Ostin on 22/11/2025.
//

import SwiftUI

// MARK: - Shake-on-trigger modifier

extension View {

    func showShakeAnimation(bool: Bool) -> some View {
        modifier(ShakeOnTrigger(trigger: bool))
    }
}

private struct ShakeOnTrigger: ViewModifier {
    /// We watch this flag; every change to it plays one shake.
    var trigger: Bool

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-9, duration: 0.06)   // initial jolt
                CubicKeyframe( 9, duration: 0.10)
                CubicKeyframe(-7, duration: 0.10)
                CubicKeyframe( 7, duration: 0.10)
                CubicKeyframe(-3, duration: 0.08)   // decaying…
                CubicKeyframe( 0, duration: 0.06)   // …back to rest
            }
        }
    }
}


// MARK: - Default show / dismiss animation
extension Animation {
    static let scoopPop: Animation = .spring(response: 0.35, dampingFraction: 0.7)
}

extension AnyTransition {
    static var scoopPop: AnyTransition {
        AnyTransition(.blurReplace).combined(with: .scale(scale: 0.8, anchor: .top))
    }
}

// MARK: - Opacity pop (scale + fade, no blur)

//Bool-driven counterpart to the `.scoopPop` transition, for chrome that must
//stay mounted: a view INSERTED mid-animation renders at the destination
//geometry instead of riding it, so these elements toggle visibility in place.
//Rides whatever animation drives the passed value.
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
