//
//  ButtonPressStyle.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

//Takes elevation in as parameter as shadow subtly changes based of shadow
struct ShrinkButtonStyle: ButtonStyle {
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
                    onPressed(isPressed: isPressed)
                }
        }
        
        func onPressed(isPressed: Bool) {
            guard !isPressed else {
                pressStart = .now
                withAnimation(.snappy(duration: 0.12)) {
                    scale = 0.9; opacity = 0.75; shadowStrength = Elevation.pressedStrength
                }
                return
            }
            // Hold off the bounce so the dip stays visible on a fast tap.
            let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) { scale = 1; shadowStrength = 1 }
                withAnimation(.easeOut(duration: 0.48)) { opacity = 1 }
            }
        }
    }
}


//Mirror of PopButtonStyle that grows and brightens instead of shrinking used for Ios 18 buttons
struct GrowButtonStyle: ButtonStyle {
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
        @State private var brightness: Double = 0
        @State private var shadowStrength: Double = 1
        @State private var pressStart: Date?

        var body: some View {
            configuration.label
                .scaleEffect(scale)
                .brightness(brightness)
                .buttonShadow(elevation, color: shadowColor, strength: shadowStrength)
                .onChange(of: configuration.isPressed) { _, isPressed in
                    onPressed(isPressed: isPressed)
                }
        }

        func onPressed(isPressed: Bool) {
            guard !isPressed else {
                pressStart = .now
                withAnimation(.snappy(duration: 0.15)) {
                    scale = 1.18; brightness = 0.2; shadowStrength = Elevation.pressedStrength
                }
                return
            }
            // Hold off the bounce so the grow stays visible on a fast tap.
            let elapsed = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.12 - elapsed)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.38)) { scale = 1; shadowStrength = 1 }
                withAnimation(.easeOut(duration: 0.48)) { brightness = 0 }
            }
        }
    }
}

extension View {
        func shrinkButton(shadow: Elevation? = nil, shadowColor: Color = .accent) -> some View {
            self
                .buttonStyle(ShrinkButtonStyle(elevation: shadow, shadowColor: shadowColor))
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5).onEnded { _ in }
                )
        }
    
    func growButton(shadow: Elevation? = nil, shadowColor: Color = .accent) -> some View {
        self
            .buttonStyle(GrowButtonStyle(elevation: shadow, shadowColor: shadowColor))
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in }
            )
    }
}
