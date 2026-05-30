//
//  GlassIfAvailableModifier.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func glassIfAvailable<S: InsettableShape>(_ shape: S = Capsule(), isClear: Bool = true, thinMaterial: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            let base: Glass = isClear ? .clear : .regular
            self
                .glassEffect(tint.map { base.tint($0) } ?? base, in: shape)
        } else {
            self
                .background {shape.fill(Color.appCanvas)}
                .overlay {shape.strokeBorder(Color.grayBackground, lineWidth: 0.4)}
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .background(Capsule().fill(thinMaterial ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear)))
        }
    }
}
