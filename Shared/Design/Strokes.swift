//
//  Strokes.swift
//  Scoop
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

//The app's only border API: every stroked corner goes through these, so the
//stroke always shares the curvature (and ideally the token) of the fill it wraps.
extension View {

    func stroke(_ radius: CGFloat, lineWidth: CGFloat = 1, color: some ShapeStyle = Color.border) -> some View {
        self
            .overlay {
                PixelSnapped(lineWidth) { width in
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(color, lineWidth: width)
                }
            }
    }

    func stroke(_ corners: RectangleCornerRadii, lineWidth: CGFloat = 1, color: some ShapeStyle = Color.border) -> some View {
        self
            .overlay {
                PixelSnapped(lineWidth) { width in
                    UnevenRoundedRectangle(cornerRadii: corners)
                        .strokeBorder(color, lineWidth: width)
                }
            }
    }

    func circleStroke(lineWidth: CGFloat, color: Color = Color.border) -> some View {
        self
            .overlay {
                PixelSnapped(lineWidth) { width in
                    Circle()
                        .stroke(color, lineWidth: width)
                }
            }
    }

    func capsuleStroke(lineWidth: CGFloat, color: Color = Color.border) -> some View {
        self
            .overlay {
                PixelSnapped(lineWidth) { width in
                    Capsule()
                        .strokeBorder(color, lineWidth: width)
                }
            }
    }
}

//A border only rasterises evenly when it covers a whole number of device pixels. 0.8pt is
//2.40px at @3x, and the leftover fringe row lands differently on the two axes — measured, the
//horizontal runs come out `1.00 1.00 0.35` while the vertical ones come out `0.50 1.00 0.35`,
//so the sides read lighter and softer than the top and bottom. Rounding the width to the
//nearest whole pixel makes all four runs identical (0.8pt becomes exactly 2px on every screen).
//A whole-point width is already a whole number of pixels, so every `lineWidth: 1` border is
//untouched. The floor of one pixel keeps a very thin hairline from rounding away to nothing.
//Its own View because @Environment only resolves inside a body — a width computed at the call
//site would never see displayScale.
private struct PixelSnapped<Content: View>: View {

    //Injected
    private let lineWidth: CGFloat
    private let content: (CGFloat) -> Content

    @Environment(\.displayScale) private var displayScale

    init(_ lineWidth: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.lineWidth = lineWidth
        self.content = content
    }

    private var snappedWidth: CGFloat {
        max(1, (lineWidth * displayScale).rounded()) / displayScale
    }

    var body: some View {
        content(snappedWidth)
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
