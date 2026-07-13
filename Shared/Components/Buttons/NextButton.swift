//
//  NextButton.swift
//  Scoop
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI

struct NextButton: View {
    let isValid: Bool
    let onTap: () -> Void
        
    var shadow: Elevation? { isValid ? .button : nil }
    var color: Color { isValid ? .accent : .fillGray}

    var body: some View {
        ScoopButton(style: .tinted(color, shadow: shadow), shape: Capsule()) {
            onTap()
        } label: {
            Image("ForwardArrow")
                .frame(width: 69, height: 44, alignment: .center) //Geometry: arrow-glyph frame (44 = min tap target)
        }
        .frame(maxWidth: .infinity, alignment: .trailing) //Positioning on screen
        .disabled(!isValid)
        .animation(.toggle, value: isValid)
    }
}

//Convenience so can just do .nextButton and it adds it to the screen in default position.
//Geometry: default 144 clears the details drawer the button floats above.
extension View {
    func nextButton(isValid: Bool, padding: CGFloat = 144, onTap: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            NextButton(isValid: isValid, onTap: onTap)
                .padding(.horizontal)
                .padding(.bottom, padding)
        }
    }
}
