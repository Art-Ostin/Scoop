//
//  WideActionButton.swift
//  Scoop
//
//  Created by Art Ostin on 20/07/2026.
//

import SwiftUI

struct WideActionButton: View {

    //Injected
    let text: String
    let isActive: Bool
    ///Recedes the fill to grey without deactivating the button — for a picker open above it.
    var isDimmed: Bool = false
    var showShadow: Bool = true
    var font: Font = .body(18, .bold)
    var height: CGFloat = 48
    var lineLimit: Int = 1
    ///Flat instead of the tinted lens — for a CTA a flight lands a flat capsule on, which must be the
    ///same pixels (the compose card). Glass draws a rim and its own shadow, both of which arrived as a
    ///dark step at the landing (device 2026-09-04).
    var glass: Bool = true

    let onTap: () -> ()

    //A dim only reaches the fill: glass, shadow and interactivity stay tied to isActive, so
    //nothing structural flips and the caller can animate the colour on its own.
    ///The resting fill, exposed so a flight landing on this button can wear exactly it from its
    ///first frame — the rule stays here, and the two can never disagree about what it lands on
    static func restingFill(isActive: Bool, isDimmed: Bool) -> Color {
        isActive && !isDimmed ? .textAccent : .fillGray
    }

    private var fill: Color { Self.restingFill(isActive: isActive, isDimmed: isDimmed) }

    var body: some View {
        ScoopButton(
            style: .tinted(fill, shadow: (showShadow && isActive) ? .button : nil, glass: isActive && glass),
            shape: .capsule,
            action: onTap
        ) {
            label
        }
        .disabled(!isActive)
    }

    private var label: some View {
        //Need Zstack, to get blur replace of text when it changes
        ZStack {
               Text(text)
                   .font(font)
                   .lineLimit(lineLimit)
                   .multilineTextAlignment(.center)
                   .id(text)
                   .transition(.blurReplace)
           }
           .animation(.transition, value: text)
           .frame(maxWidth: .infinity)
           .frame(height: 48)
           .geometryGroup()
    }
}
