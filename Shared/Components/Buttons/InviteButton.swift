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

    //Glass over an opaque disc, with the disc BEHIND the button as its own layer. A Liquid Glass lens
    //samples what lies behind its layer, not a fill drawn inside the same button: at rest that was
    //the photo (a vivid, lit tint), on the event zoom's flying capsule it was the opaque capsule
    //underneath (a deeper tint, a thin rim) — two looks, a style switch at the tap (device
    //2026-09-04). Arthur chose the deep look, so the resting button carries the same opaque disc
    //behind it that the capsule provides in flight, and the two are the same stack everywhere.
    var body: some View {
        ScoopButton(style: .tinted(Self.tint, shadow: shadow, solid: true), shape: Circle()) {
            onTap()
        } label: {
            Self.glyph
        }
        .background { Circle().fill(Self.tint) } //The lens' backdrop — see above
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
