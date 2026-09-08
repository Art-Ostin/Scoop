//
//  ShakeEffect.swift
//  Scoop
//
//  Created by Art Ostin on 22/11/2025.
//

import SwiftUI

// MARK: - Shake-on-trigger modifier

extension View {

    /// `amplitude` scales the swing only — the timing envelope is fixed, so the
    /// refusal haptic keeps sitting on the first jolt. Wider surfaces need more than 1.
    func showShakeAnimation(bool: Bool, amplitude: CGFloat = 1) -> some View {
        modifier(ShakeOnTrigger(trigger: bool, amplitude: amplitude))
    }
}

private struct ShakeOnTrigger: ViewModifier {
    /// We watch this flag; every change to it plays one shake.
    var trigger: Bool
    var amplitude: CGFloat = 1

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-9 * amplitude, duration: 0.06)   // initial jolt
                CubicKeyframe( 9 * amplitude, duration: 0.10)
                CubicKeyframe(-7 * amplitude, duration: 0.10)
                CubicKeyframe( 7 * amplitude, duration: 0.10)
                CubicKeyframe(-3 * amplitude, duration: 0.08)   // decaying…
                CubicKeyframe( 0, duration: 0.06)               // …back to rest
            }
        }
    }
}

