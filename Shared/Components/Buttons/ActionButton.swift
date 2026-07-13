//
//  ActionButton.swift
//  Scoop
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {

    let text: String
    var isValid: Bool = true
    var hPadding: CGFloat = Spacing.xl
    let onTap: () -> Void

    var color: Color { isValid ? .accent : .fillGray }
    var shadow: Elevation? { isValid ? .floating : nil }

    var body: some View {
        ScoopButton(style: .tinted(color, shadow: shadow), shape: Capsule(), action: onTap) {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, hPadding)
                .frame(height: 44) //Geometry: standard CTA height / min tap target
        }
        .disabled(!isValid)
    }
}
