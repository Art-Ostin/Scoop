//
//  InviteButton.swift
//  Scoop
//
//  Created by Art Ostin on 30/05/2026.
//

import SwiftUI



struct InviteButton: View {
    let onTap: () -> ()
    
    var shadow: Elevation? = nil
    static let tint: Color = .textAccent

    var body: some View {
        ScoopButton(style: .tinted(Self.tint, shadow: shadow, solid: true), shape: Circle(),
                    press: .grow, lensWell: .white) {
            onTap()
        } label: {
            Self.glyph
        }
    }

    ///The envelope alone — the button's own label
    static var glyph: some View {
        Image("LetterIconProfile")
            .font(.body(24, .bold))
            .foregroundStyle(Color.white)
            .scaleEffect(0.8)
            .frame(width: 42, height: 42)
    }
}
