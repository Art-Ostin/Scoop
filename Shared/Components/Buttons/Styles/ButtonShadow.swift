//
//  ButtonShadow.swift
//  Scoop
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

//two shadow method: most modern and professional
enum Elevation {
    case customGlassShadow, low, medium, high

    static let pressedStrength: Double = 0.4

    // Tight, neutral shadow that anchors the element to the surface.
    fileprivate var contact: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .customGlassShadow: (0.03, 8, 3)
        case .low:      (0.10, 2, 1)
        case .medium:   (0.12, 4, 2)
        case .high:     (0.14, 6, 3)
        }
    }

    // Soft, accent-tinted spread that gives the element lift.
    fileprivate var ambient: (opacity: Double, radius: CGFloat, y: CGFloat) {
        switch self {
        case .customGlassShadow: (0.01, 24, 9)
        case .low:      (0.06, 8, 4)
        case .medium:   (0.08, 16, 8)
        case .high:     (0.10, 28, 16)
        }
    }
}

extension View {
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
