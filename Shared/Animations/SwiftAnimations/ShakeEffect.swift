//
//  ShakeEffect.swift
//  Scoop
//
//  Created by Art Ostin on 22/11/2025.
//

import SwiftUI

// MARK: - Shake-on-trigger modifier

extension View {

    /// `amplitude` scales the swing, `stretch` the timing envelope — both default to 1, so a
    /// plain call still plays the original 0.5s jolt. Wider surfaces need more of both: more
    /// swing to read as a refusal at all, and more time or the swing crosses too fast to see.
    /// `stretch` scales every beat evenly, so the decay keeps its shape and the first jolt stays
    /// short enough that the refusal haptic still sits on it.
    func showShakeAnimation(bool: Bool, amplitude: CGFloat = 1, stretch: Double = 1) -> some View {
        modifier(ShakeOnTrigger(trigger: bool, amplitude: amplitude, stretch: stretch))
    }
}

private struct ShakeOnTrigger: ViewModifier {
    /// We watch this flag; every change to it plays one shake.
    var trigger: Bool
    var amplitude: CGFloat = 1
    var stretch: Double = 1

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-9 * amplitude, duration: 0.06 * stretch)   // initial jolt
                CubicKeyframe( 9 * amplitude, duration: 0.10 * stretch)
                CubicKeyframe(-7 * amplitude, duration: 0.10 * stretch)
                CubicKeyframe( 7 * amplitude, duration: 0.10 * stretch)
                CubicKeyframe(-3 * amplitude, duration: 0.08 * stretch)   // decaying…
                CubicKeyframe( 0, duration: 0.06 * stretch)               // …back to rest
            }
        }
    }
}
