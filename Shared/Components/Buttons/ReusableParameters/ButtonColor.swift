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



//Update potentially delete
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



//Come back to. DON't DElete!! use for
/*
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

 */
