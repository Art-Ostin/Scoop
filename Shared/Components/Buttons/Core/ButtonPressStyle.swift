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
    // Dead time between the lift and the release animation, so a fast tap still shows the
    // press. Only worth paying when there's a dim to see — scale alone reads on the way down.
    var releaseHold: Double = 0.12
    var release: (response: Double, damping: Double)

    // Shrinks and dims — the standard tinted-button press.
    static let shrink = PressEffect(scale: 0.9, opacity: 0.75, pressDuration: 0.12, release: (0.4, 0.45))
    // Shrinks without dimming — for buttons whose fill flips on tap. The dim's slow return
    // would wash out the new color, and a bouncy settle keeps the label rasterized at a
    // fractional scale (soft glyphs) long after the fill has landed. Releases at once, flat.
    static let select = PressEffect(scale: 0.9, pressDuration: 0.12, releaseHold: 0, release: (0.25, 1))
    // Grows and brightens — used for the iOS 18 glass fallback.
    static let grow = PressEffect(scale: 1.22, brightness: 0.2, pressDuration: 0.15, release: (0.35, 0.38))

    // The standard press at a fifth of the travel, for a surface a full shrink overwhelms —
    // a wide row inside a card group, whose siblings hold still while it moves.
    static let subtleShrink: PressEffect = {
        var effect = shrink.scaled(to: 0.2)
        // Releases on the same frame it is cancelled. With `instantPressDelivery` the press
        // lands on touch-down, so a touch that turns into a scroll shows it for a frame or
        // two — and it is the hold, not the shrink, that would make that blip dwell.
        effect.releaseHold = 0
        // Less overshoot than the standard 0.45 — damping runs the other way, so a higher
        // number is a smaller bounce. This rides wide, text-heavy rows, and a springier settle
        // holds their glyphs at a fractional scale long enough to read as soft.
        effect.release = (0.4, 0.65)
        return effect
    }()

    // A gentler take on a press: every amount it travels — the shrink, the dim, the brighten —
    // kept in proportion, so it reads as the same gesture rather than a slower one. Durations
    // and the release spring are deliberately NOT scaled: the spring is character, not
    // distance, and the overshoot already shrinks with the travel it settles through. Damping
    // it in proportion as well double-counts, and the press lands flat.
    func scaled(to fraction: Double) -> PressEffect {
        PressEffect(
            scale: 1 - (1 - scale) * CGFloat(fraction),
            opacity: 1 - (1 - opacity) * fraction,
            brightness: brightness * fraction,
            pressDuration: pressDuration,
            releaseHold: releaseHold,
            release: release
        )
    }
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
        let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? effect.releaseHold
        let hold = max(0, effect.releaseHold - elapsed)
        // No hold means release on this frame — an async hop would cost one anyway.
        guard hold > 0 else { return release() }
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) { release() }
    }

    func release() {
        withAnimation(.spring(response: effect.release.response, dampingFraction: effect.release.damping)) {
            scale = 1; shadowStrength = 1
        }
        withAnimation(.easeOut(duration: 0.48)) { opacity = 1; brightness = 0 }
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

    @Environment(\.scenePhase) private var scenePhase
    @State private var isPressed = false
    // Latched once the touch travels past the slop: a drag never fires the action,
    // even when the finger circles back near its start before release.
    @State private var wasDrag = false

    // Finger travel below this still counts as a tap. Straight-line (hypot), so the
    // slop nests inside container drag recognizers' Euclidean slop (the invite card's
    // dismiss drag claims at 12pt) — a per-axis box would let ~13pt diagonals read as taps.
    private static let tapSlop: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .modifier(PressAnimation(isPressed: isPressed, effect: effect, elevation: elevation, tint: tint))
            .contentShape(Rectangle())
            // GLOBAL coordinates: a view that rides its container's drag (the invite card
            // chasing a dismiss flick) cancels the finger's travel out of a local-space
            // translation, so a committed drag would read as a tap at release.
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if hypot(value.translation.width, value.translation.height) >= Self.tapSlop {
                            wasDrag = true
                            isPressed = false // turned into a drag — let the press go
                        } else if !wasDrag {
                            isPressed = true
                        }
                    }
                    .onEnded { value in
                        isPressed = false
                        let dragged = wasDrag
                        wasDrag = false
                        // Only fire on a true tap: never after a drag, and only released
                        // where it started.
                        if let action, !dragged,
                           hypot(value.translation.width, value.translation.height) < Self.tapSlop {
                            action()
                        }
                    }
            )
            // A cancelled touch (incoming call, app switch, system alert) never
            // delivers onEnded, which owns the resets — without these the press
            // would strand shrunk and the latch would eat the next tap
            // (TimeCustomMenu's guard, mirrored).
            .onChange(of: scenePhase) { _, phase in
                guard phase != .active else { return }
                isPressed = false
                wasDrag = false
            }
            .onDisappear {
                isPressed = false
                wasDrag = false
            }
    }
}

extension View {

    func shrinkButton(shadow: Elevation? = nil, tint: Color = .accent) -> some View {
        pressButton(.shrink, shadow: shadow, tint: tint)
    }

    func growButton(shadow: Elevation? = .glass, tint: Color = .accent) -> some View {
        pressButton(.grow, shadow: shadow, tint: tint)
    }

    func selectButton(shadow: Elevation? = nil, tint: Color = .accent) -> some View {
        pressButton(.select, shadow: shadow, tint: tint)
    }

    func pressButton(_ effect: PressEffect, shadow: Elevation?, tint: Color) -> some View {
        buttonStyle(PressButtonStyle(effect: effect, elevation: shadow, tint: tint))
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in }) //allows long presses, fixes bug
    }

    func subtleShrinkButton(shadow: Elevation? = nil, tint: Color = .accent) -> some View {
        pressButton(.subtleShrink, shadow: shadow, tint: tint)
    }

    // Apply the shrink press directly to any view (e.g. an Image) without wrapping it in a Button.
    func shrinkPress(shadow: Elevation? = nil, tint: Color = .accent, action: (() -> Void)? = nil) -> some View {
        press(.shrink, shadow: shadow, tint: tint, action: action)
    }

    func subtleShrinkPress(shadow: Elevation? = nil, tint: Color = .accent, action: (() -> Void)? = nil) -> some View {
        press(.subtleShrink, shadow: shadow, tint: tint, action: action)
    }

    func press(_ effect: PressEffect, shadow: Elevation?, tint: Color, action: (() -> Void)?) -> some View {
        modifier(PressEffectModifier(effect: effect, elevation: shadow, tint: tint, action: action))
    }
}
