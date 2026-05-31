//
//  ButtonPressStyle.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

struct PopButtonStyle: ButtonStyle {
    var elevation: Elevation?
    var shadowColor: Color = .accent

    func makeBody(configuration: Configuration) -> some View {
        PressableLabel(configuration: configuration, elevation: elevation, shadowColor: shadowColor)
    }

    private struct PressableLabel: View {
        let configuration: Configuration
        let elevation: Elevation?
        let shadowColor: Color
        @State private var scale: CGFloat = 1
        @State private var opacity: Double = 1
        @State private var shadowStrength: Double = 1
        @State private var pressStart: Date?

        var body: some View {
            configuration.label
                .scaleEffect(scale)
                .opacity(opacity)
                .buttonShadow(elevation, color: shadowColor, strength: shadowStrength)
                .onChange(of: configuration.isPressed) { _, isPressed in
                    isPressed ? press() : release()
                }
        }

        private func press() {
            pressStart = .now
            withAnimation(.snappy(duration: 0.12)) {
                scale = 0.9
                opacity = 0.75
                shadowStrength = Elevation.pressedStrength
            }
        }

        private func release() {
            // Hold off the bounce so the dip stays visible on a fast tap.
            let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) {
                    scale = 1
                    shadowStrength = 1
                }
                withAnimation(.easeOut(duration: 0.48)) { opacity = 1 }
            }
        }
    }
}

extension ButtonStyle where Self == PopButtonStyle {
    static func pop(_ elevation: Elevation? = nil, color: Color = .accent) -> PopButtonStyle {
        .init(elevation: elevation, shadowColor: color)
    }
}

extension View {
    func customButtonPress(_ elevation: Elevation? = nil, shadowColor: Color = .accent) -> some View {
        self
            .buttonStyle(.pop(elevation, color: shadowColor))
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in }
            )
    }
}
