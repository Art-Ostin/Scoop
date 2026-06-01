//
//  GlassCircleButton.swift
//  Scoop
//
//  Created by Art Ostin on 01/06/2026.
//

import SwiftUI

struct GlassCircleButton<Content: View>: View {
    var padding: CGFloat = 0
    let action: () -> Void
    var buttonLabel: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                buttonLabel()
                    .padding(padding)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.clear)
            .foregroundStyle(Color.black)
        } else {
            Button(action: action) {
                buttonLabel()
                    .padding(8)//Keeps size of pre Ios 26 and Ios 26 buttons the same
                    .background(Circle().fill(.ultraThinMaterial).brightness(0.07))
                    .foregroundStyle(Color.black)
            }
            .customButtonGrowAndShadow(.customGlassShadow)
        }
    }
}
