//
//  ButtonShadow.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

enum Elevation {
    case low, medium, high

    /// Shadow strength when the button is pressed. Lower = the button sinks
    /// toward the surface as its shadow tightens.
    static let pressedStrength: Double = 0.4

    /// Tight, neutral shadow that anchors the element to the surface.
    fileprivate var contact: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .low:    (0.10, 2, 1)
        case .medium: (0.12, 4, 2)
        case .high:   (0.14, 6, 3)
        }
    }

    /// Soft, accent-tinted spread that gives the element lift.
    fileprivate var ambient: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .low:    (0.06, 8, 4)
        case .medium: (0.08, 16, 8)
        case .high:   (0.10, 28, 16)
        }
    }
}

extension View {
    /// Layered, iOS 26 (Liquid Glass) shadow. A tight neutral contact layer
    /// grounds the element on the surface; a soft tinted ambient layer gives it
    /// lift. Pass `nil` for no shadow. `strength` (0...1) scales both layers so
    /// the shadow can be animated (e.g. dip on press).
    @ViewBuilder
    func buttonShadow(_ elevation: Elevation?, color: Color = .accent, strength: Double = 1) -> some View {
        if let elevation {
            let s = min(max(strength, 0), 1)
            self
                .shadow(color: .black.opacity(elevation.contact.opacity * s), radius: elevation.contact.radius, x: 0, y: elevation.contact.y)
                .shadow(color: color.opacity(elevation.ambient.opacity * s), radius: elevation.ambient.radius, x: 0, y: elevation.ambient.y)
        } else {
            self
        }
    }
}
