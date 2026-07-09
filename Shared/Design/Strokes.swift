//
//  Strokes.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

extension View {

    func rectangleStroke(radius: CGFloat, lineWidth: CGFloat, color: Color = Color.border) -> some View {
        self
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(color, lineWidth: lineWidth)
            }
    }

    func rectangleStroke(corners: RectangleCornerRadii, lineWidth: CGFloat, color: Color = Color.border) -> some View {
        self
            .overlay {
                UnevenRoundedRectangle(cornerRadii: corners, style: .continuous)
                    .strokeBorder(color, lineWidth: lineWidth)
            }
    }

    func circleStroke(lineWidth: CGFloat, color: Color = Color.border) -> some View {
        self
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: lineWidth)
            }
    }
}

extension RectangleCornerRadii {
    /// All four corners the same.
    init(uniform r: CGFloat) {
        self.init(topLeading: r, bottomLeading: r, bottomTrailing: r, topTrailing: r)
    }
    /// The two top corners share `top`, the two bottom corners share `bottom`.
    init(top: CGFloat, bottom: CGFloat) {
        self.init(topLeading: top, bottomLeading: bottom, bottomTrailing: bottom, topTrailing: top)
    }
    /// Same radii flipped about the horizontal axis (top ⇄ bottom). Used to pair a
    /// card with a footer beneath it so their facing edges match.
    var verticallyMirrored: RectangleCornerRadii {
        RectangleCornerRadii(topLeading: bottomLeading, bottomLeading: topLeading,
                             bottomTrailing: topTrailing, topTrailing: bottomTrailing)
    }
}
