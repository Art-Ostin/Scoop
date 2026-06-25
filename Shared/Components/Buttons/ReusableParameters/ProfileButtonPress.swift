//
//  ProfileButtonPress.swift
//  Scoop Test
//
//  Created by Art Ostin on 25/06/2026.
//

import SwiftUI

struct ShrinkPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

extension View {
    func profileShrinkPress(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
        }
        .buttonStyle(ShrinkPressButtonStyle())
    }
}
