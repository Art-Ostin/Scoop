//
//  ButtonPressStyle.swift
//  Scoop
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

// The pressed look for a button. Released values are always identity
// (scale 1, opacity 1, brightness 0), so each preset only sets what it changes.
struct PressEffect {
    var scale: CGFloat
    var opacity: Double = 1
    var brightness: Double = 0
    var pressDuration: Double
    var release: (response: Double, damping: Double)

    // Shrinks and dims — the standard tinted-button press.
    static let shrink = PressEffect(scale: 0.9, opacity: 0.75, pressDuration: 0.12, release: (0.4, 0.45))
    // Grows and brightens — used for the iOS 18 glass fallback.
    static let grow = PressEffect(scale: 1.22, brightness: 0.2, pressDuration: 0.15, release: (0.35, 0.38))
}

// Animates the press look (scale/opacity/brightness/shadow) whenever `isPressed`
// flips. Both entry points feed it: PressButtonStyle from the system's
// configuration.isPressed, PressEffectModifier from its own drag gesture.
private struct PressAnimation: ViewModifier {
    let isPressed: Bool
    let effect: PressEffect
    let elevation: Elevation?
    let tint: Color
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var brightness: Double = 0
    @State private var shadowStrength: Double = 1
    @State private var pressStart: Date?

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .brightness(brightness)
            .shadow(elevation, tint: tint, strength: shadowStrength)
            .onChange(of: isPressed) { _, isPressed in onPressed(isPressed) }
    }

    func onPressed(_ isPressed: Bool) {
        guard !isPressed else {
            pressStart = .now
            withAnimation(.snappy(duration: effect.pressDuration)) {
                scale = effect.scale; opacity = effect.opacity; brightness = effect.brightness
                shadowStrength = Elevation.pressedStrength
            }
            return
        }
        // Hold off the bounce so the press stays visible on a fast tap.
        let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) {
            withAnimation(.spring(response: effect.release.response, dampingFraction: effect.release.damping)) {
                scale = 1; shadowStrength = 1
            }
            withAnimation(.easeOut(duration: 0.48)) { opacity = 1; brightness = 0 }
        }
    }
}

// Shadow subtly changes with elevation, so it's taken as a parameter.
struct PressButtonStyle: ButtonStyle {
    var effect: PressEffect
    var elevation: Elevation?
    var tint: Color = .accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(PressAnimation(isPressed: configuration.isPressed, effect: effect, elevation: elevation, tint: tint))
    }
}

// Same press look as PressButtonStyle, but driven by a gesture so it can be
// applied to any view (e.g. an Image) without wrapping it in a Button.
struct PressEffectModifier: ViewModifier {
    var effect: PressEffect
    var elevation: Elevation?
    var tint: Color = .accent
    var action: (() -> Void)?

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .modifier(PressAnimation(isPressed: isPressed, effect: effect, elevation: elevation, tint: tint))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { value in
                        isPressed = false
                        // Only fire if released inside the view's bounds.
                        if let action,
                           value.translation.width.magnitude < 10,
                           value.translation.height.magnitude < 10 {
                            action()
                        }
                    }
            )
    }
}

extension View {

    func shrinkButton(shadow: Elevation? = nil, tint: Color = .accent) -> some View {
        pressButton(.shrink, shadow: shadow, tint: tint)
    }

    func growButton(shadow: Elevation? = .glass, tint: Color = .accent) -> some View {
        pressButton(.grow, shadow: shadow, tint: tint)
    }

    private func pressButton(_ effect: PressEffect, shadow: Elevation?, tint: Color) -> some View {
        buttonStyle(PressButtonStyle(effect: effect, elevation: shadow, tint: tint))
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in }) //allows long presses, fixes bug
    }

    // Apply the shrink press directly to any view (e.g. an Image) without wrapping it in a Button.
    func shrinkPress(shadow: Elevation? = nil, tint: Color = .accent, action: (() -> Void)? = nil) -> some View {
        modifier(PressEffectModifier(effect: .shrink, elevation: shadow, tint: tint, action: action))
    }
}
