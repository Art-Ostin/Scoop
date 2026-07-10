//
//  ButtonShadow.swift
//  Scoop
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

// How buttons wear the shared elevation ramp (Shared/Design/Shadows.swift):
// the press styles animate `.shadow(_:tint:strength:)`'s strength down to this
// value while the button is held, so the control visibly settles toward the
// surface, then springs back to full lift on release.
extension Elevation {
    static let pressedStrength: Double = 0.4
}
