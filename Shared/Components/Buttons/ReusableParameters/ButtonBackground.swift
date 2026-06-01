//
//  GlassIfAvailable.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI


//Applies a colour Background to a button and glass background if in glass mode
extension View {
    
    func buttonBackground<S: InsettableShape>(_ shape: S, color: Color = .accent) -> some View {
        let base = foregroundStyle(.white)
        return Group {
            if #available(iOS 26.0, *) {
                base.glassEffect(.regular.tint(color), in: shape)
            } else {
                base
                    .background(shape.fill(color))
                    .buttonShadow(.customGlassShadow)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .padding(-16)
    }
}
