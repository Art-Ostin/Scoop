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

