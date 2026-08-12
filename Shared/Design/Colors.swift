//
//  Colors.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

extension Color {

    //1. Four different Text levels
    static let textPrimary = Color(red: 0.14, green: 0.13, blue: 0.12)

    static let textSecondary = Color.black.opacity(0.55)

    static let textTertiary = Color.black.opacity(0.35)

    static let textPlaceholder = Color.black.opacity(0.22) //Glancable no sentences this light


    //2. Grays used throughout app — all on the palette's warm axis (hue 30°, ~2% saturation),
    //so a gray never reads cool against appCanvas. A neutral gray here looks blue by contrast.
    static let border = Color(red: 0.88, green: 0.87, blue: 0.86)

    static let borderStrong = Color(red: 0.75, green: 0.74, blue: 0.73) //Outlined controls that need to hold their own against a filled sibling (the decline button).

    static let fillGray = Color(red: 0.94, green: 0.93, blue: 0.92)


    //3. Background Color App
    static let appCanvas = Color(red: 0.99, green: 0.98, blue: 0.97)

    static let canvasSunken = Color(red: 0.97, green: 0.96, blue: 0.95) //Color(red: 0.96, green: 0.95, blue: 0.91) //Recessed canvas for card-on-canvas screens (edit profile) — a step deeper and warmer than appCanvas so white cards read as raised.

    static let blackFill = Color(red: 0.13, green: 0.13, blue: 0.13) //Opaque near-black fill for selected cells & small controls (selected day, clear buttons) — never for type.


    //4. App Pallette
    // The brand accent lives in Assets.xcassets/AccentColor (drives system tinting) — use .accent.
    static let textAccent = Color(red: 0.55, green: 0, blue: 0.25) //Slightly darker accent, for accent-colored text on light backgrounds — and the wide CTA fill, which wears the deeper tone.

    static let actionBlue = Color(red: 0, green: 0.48, blue: 1) //Third-party / external actions that hand off out of the app (Google Maps, Reviews).


    //5. Status Colors
    static let successGreen = Color(red: 0, green: 0.47, blue: 0.41) //Confirmed / accepted / valid states only.

    static let dangerRed = Color(red: 0.94, green: 0.08, blue: 0.24)

    static let warningYellow = Color(red: 1, green: 0.75, blue: 0.03)
}
