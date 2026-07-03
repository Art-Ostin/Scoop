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

// Shadow subtly changes with elevation, so it's taken as a parameter.
struct PressButtonStyle: ButtonStyle {
    var effect: PressEffect
    var elevation: Elevation?
    var shadowColor: Color = .accent

    func makeBody(configuration: Configuration) -> some View {
        PressableLabel(configuration: configuration, effect: effect, elevation: elevation, shadowColor: shadowColor)
    }

    private struct PressableLabel: View {
        let configuration: Configuration
        let effect: PressEffect
        let elevation: Elevation?
        let shadowColor: Color
        @State private var scale: CGFloat = 1
        @State private var opacity: Double = 1
        @State private var brightness: Double = 0
        @State private var shadowStrength: Double = 1
        @State private var pressStart: Date?

        var body: some View {
            configuration.label
                .scaleEffect(scale)
                .opacity(opacity)
                .brightness(brightness)
                .buttonShadow(elevation, color: shadowColor, strength: shadowStrength)
                .onChange(of: configuration.isPressed) { _, isPressed in onPressed(isPressed) }
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
}

// Same press look as PressButtonStyle, but driven by a gesture so it can be
// applied to any view (e.g. an Image) without wrapping it in a Button.
struct PressEffectModifier: ViewModifier {
    var effect: PressEffect
    var elevation: Elevation?
    var shadowColor: Color = .accent
    var action: (() -> Void)?

    @State private var isPressed = false
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
            .buttonShadow(elevation, color: shadowColor, strength: shadowStrength)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onPressed(true)
                    }
                    .onEnded { value in
                        isPressed = false
                        onPressed(false)
                        // Only fire if released inside the view's bounds.
                        if let action,
                           value.translation.width.magnitude < 10,
                           value.translation.height.magnitude < 10 {
                            action()
                        }
                    }
            )
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

extension View {

    func shrinkButton(shadow: Elevation? = nil, shadowColor: Color = .accent) -> some View {
        pressButton(.shrink, shadow: shadow, shadowColor: shadowColor)
    }

    func growButton(shadow: Elevation? = .customGlassShadow, shadowColor: Color = .accent, brightness: Double? = nil) -> some View {
        var effect = PressEffect.grow
        if let brightness { effect.brightness = brightness }
        return pressButton(effect, shadow: shadow, shadowColor: shadowColor)
    }

    private func pressButton(_ effect: PressEffect, shadow: Elevation?, shadowColor: Color) -> some View {
        buttonStyle(PressButtonStyle(effect: effect, elevation: shadow, shadowColor: shadowColor))
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in }) //allows long presses, fixes bug
    }

    // Apply the press effect directly to any view (e.g. an Image).
    func growPress(shadow: Elevation? = .customGlassShadow, shadowColor: Color = .accent, brightness: Double? = nil, action: (() -> Void)? = nil) -> some View {
        var effect = PressEffect.grow
        if let brightness { effect.brightness = brightness }
        return modifier(PressEffectModifier(effect: effect, elevation: shadow, shadowColor: shadowColor, action: action))
    }
    
    //Same for the shrink Press
    func shrinkPress(shadow: Elevation? = nil, shadowColor: Color = .accent, action: (() -> Void)? = nil) -> some View {
        modifier(PressEffectModifier(effect: .shrink, elevation: shadow, shadowColor: shadowColor, action: action))
    }
}
