//
//  GlassIfAvailable.swift
//  Scoop Test
//
//  Created by Art Ostin on 31/05/2026.
//

import SwiftUI

extension View {
    
    func buttonBackground<S: InsettableShape>(_ shape: S, color: Color = .accent) -> some View {
        self
            .foregroundStyle(.white)
            .buttonColourBackground(shape, tint: color)
            .padding(16)
            .contentShape(Rectangle())
            .padding(-16)
    }
}


extension View {
    @ViewBuilder
    func buttonColourBackground<S: InsettableShape>(_ shape: S, tint: Color = .accent) -> some View {
        if #available(iOS 26.0, *) {
            self
            .glassEffect(.regular.tint(tint), in: shape)
        } else {
            self
            .background(shape.fill(tint))
        }
    }
}








//Use when I don't have access to the .navigationBar
extension View {
    @ViewBuilder
    func hoverButton<S: InsettableShape>(_ shape: S = Capsule(), tint: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            self
                .foregroundStyle(Color.white)
                .buttonStyle(.glassProminent)
//                .buttonBorderShape(shape as! ButtonBorderShape)
                .tint(tint)
        } else {
            self
                .background {shape.fill(Color.appCanvas)}
                .overlay {shape.strokeBorder(Color.grayBackground, lineWidth: 0.4)}
                .customButtonPressAndShadow(.high, shadowColor: .black)
//                .background(Capsule().fill(thinMaterial ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear)))
        }
    }
}
