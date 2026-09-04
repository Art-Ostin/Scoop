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

    ///The circle's own tint, exposed so a flight morphing this button away sheds exactly this colour
    static let tint: Color = .accent

    var body: some View {
        ScoopButton(style: .tinted(Self.tint, shadow: shadow), shape: Circle()) { //.accent.black.mix(with: .accent, by: 0.2)
            onTap()
        } label: {
            Image("LetterIconProfile")
                .font(.body(24, .bold))
                .foregroundStyle(Color.white)
                .scaleEffect(0.8)
                .frame(width: 42, height: 42)
        }
    }
}
