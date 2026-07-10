//
//  Shadows.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

/// The app's single elevation ramp. Every resting drop shadow in Scoop is one of
/// these levels, worn through `.shadow(_:tint:strength:)` below — raw
/// `.shadow(color:radius:x:y:)` is allowed only in this file and in measured
/// system-replication specs (menu platters, ProfileMorph), which deliberately
/// sit outside the ramp the same way CornerRadius keeps measured stand-ins.
///
/// The light source is fixed directly above the screen: x is always 0 and every
/// shadow falls downward. A level is two layers — a tight *contact* shadow that
/// anchors the view to the surface beneath it, and a wide, faint *ambient*
/// layer that conveys lift. Rising through the ramp, the ambient layer travels
/// further and blurs wider while staying faint: near things cast sharp dark
/// shadows, distant things cast broad soft ones.
enum Elevation {

    /// A whisper for stroked surfaces — the stroke provides the definition,
    /// the shadow only hints at depth. Content cards and small stroked icons.
    case card
    /// Resting image cards: profile and invite imagery.
    case image
    /// Lifted controls: CTA buttons, chips, picked-up or selected elements.
    case button
    /// The top of the ramp — surfaces hovering over content: alerts, dropdowns,
    /// notifications, map controls, the tab bar, prominent CTAs, menu platters
    /// (pre-26 fallback), expanded modal cards.
    case floating

    /// Role alias: the pre-26 glass stand-ins wear the card whisper (real glass
    /// draws its own shadow on iOS 26, so the fallback only hints).
    static let glass: Elevation = .card

    struct Layer {
        let opacity: Double
        let radius: CGFloat
        let y: CGFloat
    }

    var contact: Layer {
        switch self {
        case .card:     Layer(opacity: 0.03, radius: 8, y: 3)
        case .image:    Layer(opacity: 0.05, radius: 4, y: 0)
        case .button:   Layer(opacity: 0.12, radius: 4, y: 2)
        case .floating: Layer(opacity: 0.06, radius: 10, y: 2)
        }
    }

    var ambient: Layer {
        switch self {
        case .card:     Layer(opacity: 0.01, radius: 24, y: 9)
        case .image:    Layer(opacity: 0.07, radius: 6, y: 7)
        case .button:   Layer(opacity: 0.08, radius: 16, y: 8)
        case .floating: Layer(opacity: 0.14, radius: 24, y: 14)
        }
    }
}

extension View {

    /// The one way views wear a shadow. `tint` colors only the ambient layer
    /// (tinted CTAs glow their own color); the contact layer is always black.
    /// `strength` scales both opacities, so a shadow can fade in and out
    /// without changing the view's structure — pass nil only for
    /// configurations that never show one.
    @ViewBuilder
    func shadow(_ elevation: Elevation?, tint: Color = .black, strength: Double = 1) -> some View {
        if let elevation {
            let s = min(max(strength, 0), 1)
            let contact = elevation.contact
            let ambient = elevation.ambient
            shadow(color: .black.opacity(contact.opacity * s), radius: contact.radius, x: 0, y: contact.y)
                .shadow(color: tint.opacity(ambient.opacity * s), radius: ambient.radius, x: 0, y: ambient.y)
        } else {
            self
        }
    }
}
