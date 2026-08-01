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
    var lineLimit: Int = 1

    let onTap: () -> ()

    //A dim only reaches the fill: glass, shadow and interactivity stay tied to isActive, so
    //nothing structural flips and the caller can animate the colour on its own.
    private var fill: Color { isActive && !isDimmed ? .textAccent : .fillGray }

    var body: some View {
        ScoopButton(
            style: .tinted(fill,
                           shadow: (showShadow && isActive) ? .button : nil,
                           glass: isActive),
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
