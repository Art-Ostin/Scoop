//
//  Shadows.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI


extension View {

    @ViewBuilder
    func cardShadow(showShadow: Bool) -> some View {
        if showShadow {
            self
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
        } else {
            self
        }
    }

    // Tight lift that anchors small solid controls (chips, pill buttons, the clock).
    func chipShadow(_ show: Bool = true) -> some View {
        shadow(color: .black.opacity(show ? 0.15 : 0), radius: 1, x: 0, y: 2)
    }

    // Barely-there lift for hairline-stroked icon buttons.
    func microShadow(_ show: Bool = true) -> some View {
        shadow(color: .black.opacity(show ? 0.05 : 0), radius: 1, x: 0, y: 1.5)
    }
}

enum ShadowStyle {
    case card
    case floating

    // (opacity, radius, yOffset)
    var contact: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .card:     (0.05, 4, 0)
        case .floating: (0.06, 10, 2)
        }
    }

    var ambient: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .card:     (0.07, 6, 7)
        case .floating: (0.14, 24, 14)
        }
    }
}

private struct CustomShadowModifier: ViewModifier {
    let style: ShadowStyle
    let strength: Double

    func body(content: Content) -> some View {
        let s = min(max(strength, 0), 1)
        let contact = style.contact
        let ambient = style.ambient

        content
            .shadow(color: .black.opacity(contact.opacity * s), radius: contact.radius, x: 0, y: contact.y)
            .shadow(color: .black.opacity(ambient.opacity * s), radius: ambient.radius, x: 0, y: ambient.y)
    }
}

extension View {

    func customShadow(_ style: ShadowStyle = .card, strength: Double = 1) -> some View {
        modifier(CustomShadowModifier(style: style, strength: strength))
    }
}
