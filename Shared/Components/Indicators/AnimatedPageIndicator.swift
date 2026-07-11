//
//  AnimatedPageIndicator.swift
//  Scoop
//
//  Created by Art Ostin on 28/05/2026.
//
import SwiftUI

struct AnimatedPageIndicator: View {
    let count: Int
    let progress: Double

    var dotSize: CGFloat = 6
    var inactiveDotSize: CGFloat = 6
    var activeWidth: CGFloat = 12
    var spacing: CGFloat = 8
    //Dots shown at once. Overflowing rows become a sliding window that tapers
    //toward its edges instead of growing wider with every extra page.
    var maxVisible: Int = 5

    var isInviteIndicator: Bool { inactiveDotSize == 5 }

    private var visibleCount: Int { min(count, maxVisible) }

    var body: some View {
        let row = layout(at: progress)
        //Centre the packed cluster in a fixed frame so the overlay never shifts.
        let inset = (steadyWidth - row.width) / 2
        ZStack(alignment: .leading) {
            ForEach(0..<count, id: \.self) { i in
                let dot = row.dots[i]
                if dot.width > 0 {
                    capsule(closeness: dot.closeness)
                        .frame(width: dot.width, height: dot.height)
                        .offset(x: inset + dot.x - dot.width / 2)
                }
            }
        }
        .frame(width: steadyWidth, height: dotSize, alignment: .leading)
    }

    private func capsule(closeness: Double) -> some View {
        Capsule()
            .fill(Color.border)
            .opacity(isInviteIndicator ? 1 - closeness : 1)
            .overlay(
                Group {
                    if isInviteIndicator {
                        Capsule()
                            .strokeBorder(Color.textSecondary, lineWidth: 1.3)
                    } else {
                        Capsule()
                            .fill(.primary)
                    }
                }
                .opacity(closeness)
            )
    }

    private struct Dot {
        let width: CGFloat
        let height: CGFloat
        let x: CGFloat //Centre, in cluster coordinates
        let closeness: Double
    }

    //Dots pack cumulatively: each gap scales with its two dots' sizes, so
    //tapered dots sit proportionally closer instead of on a fixed grid, and
    //hidden dots collapse to nothing.
    private func layout(at progress: Double) -> (dots: [Dot], width: CGFloat) {
        let window = window(at: progress)
        var dots: [Dot] = []
        var cursor: CGFloat = 0
        var previousScale: CGFloat?
        for index in 0..<count {
            let distance = abs(progress - Double(index))
            let closeness = max(0, 1 - distance)
            let scale = taper(for: distance) * windowFade(at: Double(index) - window)
            let width = (inactiveDotSize + (activeWidth - inactiveDotSize) * closeness) * scale
            let height = (inactiveDotSize + (dotSize - inactiveDotSize) * closeness) * scale
            if let previousScale { cursor += spacing / 2 * (previousScale + scale) }
            dots.append(Dot(width: width, height: height, x: cursor + width / 2, closeness: closeness))
            cursor += width
            previousScale = scale
        }
        return (dots, cursor)
    }

    //The cluster's width at a settled, unclamped page — used as the fixed frame
    //so the row doesn't breathe as dots taper in and out at the ends.
    private var steadyWidth: CGFloat {
        layout(at: Double((visibleCount - 1) / 2)).width
    }

    //Continuous index of the first visible slot: keeps the active dot centred,
    //clamped so the window never runs past either end of the row.
    private func window(at progress: Double) -> Double {
        let centered = progress - Double(visibleCount - 1) / 2
        return min(max(centered, 0), Double(count - visibleCount))
    }

    //Full size for the active dot and its immediate neighbours, then each step
    //further out shrinks (~0.6, ~0.36, …). Only once the row overflows.
    private func taper(for distance: Double) -> CGFloat {
        guard count > maxVisible else { return 1 }
        return CGFloat(pow(0.6, max(0, distance - 1)))
    }

    //1 inside the window, collapsing to 0 across the slot just past either edge.
    private func windowFade(at slot: Double) -> CGFloat {
        let edge = min(slot + 1, Double(visibleCount) - slot)
        return CGFloat(min(max(edge, 0), 1))
    }
}
