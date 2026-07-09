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
        
    var shadow: Elevation? { isValid ? .medium : nil }
    var color: Color { isValid ? .accent : .fillGray}

    var body: some View {
        ScoopButton(style: .tinted(color, shadow: shadow), shape: Capsule()) {
            onTap()
        } label: {
            Image("ForwardArrow")
                .frame(width: 69, height: 44, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .trailing) //Positioning on screen
        .disabled(!isValid)
        .animation(.spring(.snappy), value: isValid)
    }
}

//Convenience so can just do .nextButton add adds it to screen in default position
extension View {
    func nextButton(isValid: Bool, padding: CGFloat = 144, onTap: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            NextButton(isValid: isValid, onTap: onTap)
                .padding(.horizontal)
                .padding(.bottom, padding)
        }
    }
}
