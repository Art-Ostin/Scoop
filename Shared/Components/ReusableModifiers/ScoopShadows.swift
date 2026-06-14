//
//  ScoopShadows.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI


extension View {

    func cardShadow(color: Color) -> some View {
        self
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .shadow(color: color.opacity(0.04), radius: 20, x: 0, y: 0)
    }
}

enum ShadowStyle {
    case card
    case floating
    case even

    // (opacity, radius, yOffset)
    var contact: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .card:     (0.05, 4, 0)
        case .floating: (0.06, 10, 2)
        case .even:     (0.05, 6, 0)
        }
    }

    var ambient: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .card:     (0.07, 6, 7)
        case .floating: (0.14, 24, 14)
        case .even:     (0.08, 16, 0)
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
