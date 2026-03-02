//
//  RoundedTriangle.swift
//  Scoop
//
//  Created by Art Ostin on 02/03/2026.
//

import SwiftUI


struct RoundedTriangle: Shape {
    var radius: CGFloat = 40

    func path(in rect: CGRect) -> Path {
        let a = CGPoint(x: rect.minX, y: rect.maxY) // bottom-left
        let b = CGPoint(x: rect.minX, y: rect.minY) // top-left
        let c = CGPoint(x: rect.maxX, y: rect.maxY) // bottom-right (rounded)

        let hyp = hypot(b.x - c.x, b.y - c.y)
        let r = min(radius, rect.width / 2, hyp / 2)

        // Points where the rounded corner starts/ends
        let onBottom = CGPoint(x: c.x - r, y: c.y)
        let onHypotenuse = CGPoint(
            x: c.x + (b.x - c.x) * (r / hyp),
            y: c.y + (b.y - c.y) * (r / hyp)
        )

        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        p.addLine(to: onHypotenuse)
        p.addQuadCurve(to: onBottom, control: c) // round bottom-right
        p.addLine(to: a)
        p.closeSubpath()
        return p
    }
}
