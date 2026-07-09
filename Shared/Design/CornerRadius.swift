//
//  CornerRadius.swift
//  Scoop
//
//  Created by Art Ostin on 02/07/2026.
//

import SwiftUI

/// Radius rules (every corner `.continuous`):
/// 1. A free-standing full-width photo *is* a card → `photoCard`.
/// 2. A shape inset inside a rounded container derives its radius → `nested(in:inset:)`.
///    Never give a parent and child the same radius — the corner gap swells.
/// 3. Small square imagery (thumbs, grid cells ≤ ~80pt) → `thumb`.
/// 4. People photos are `Circle`s, pills are `Capsule`s — exempt from 1–3.
/// When card content continues below an image, keep the top concentric and drop
/// the bottom to `sm` (see `CardImageScrollView`).
enum CornerRadius {

    // Size scale
    static let xs: CGFloat = 8    // chips, small tags
    static let sm: CGFloat = 12   // buttons, inputs, rows
    static let md: CGFloat = 16   // default card
    static let lg: CGFloat = 20   // large cards
    static let xl: CGFloat = 24   // sheets, hero images
    static let xxl: CGFloat = 32  // full-bleed / large surfaces

    // Semantic tokens
    static let photoCard = xl     // free-standing full-width image (16pt gutters)
    static let thumb = sm         // small square imagery (40–80pt)

    /// Concentric radius for a shape inset inside a rounded parent:
    /// inner = outer − inset, floored so tight insets never read fully square.
    static func nested(in parent: CGFloat, inset: CGFloat, minimum: CGFloat = 4) -> CGFloat {
        max(parent - inset, minimum)
    }
}

//Standard image clips — continuous corners so curvature matches system chrome
extension View {

    func imageClip(_ radius: CGFloat = CornerRadius.photoCard) -> some View {
        clipShape(.rect(cornerRadius: radius, style: .continuous))
    }

    func imageClip(top: CGFloat, bottom: CGFloat) -> some View {
        clipShape(.rect(
            topLeadingRadius: top,
            bottomLeadingRadius: bottom,
            bottomTrailingRadius: bottom,
            topTrailingRadius: top,
            style: .continuous
        ))
    }
}
