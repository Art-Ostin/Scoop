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
    static let tint: Color = .textAccent

    //Glass over an opaque disc, its look pinned by a white well (ScoopButton.lensWell — the why is on
    //LensWell): the adaptive lens used to go vivid once the profile card's dark scrim landed under it
    //and deep again as the event zoom's flight faded that scrim out beneath its flying copy — a style
    //switch at the tap (device 2026-09-04). Arthur chose the deep look everywhere. `.grow` press: a
    //shrink revealed the well as a white ring; the well rides inside the press, so the disc grows whole.
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
