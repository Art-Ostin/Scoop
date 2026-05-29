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
    var activeWidth: CGFloat = 12
    var spacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { i in
                let distance = abs(progress - Double(i))
                let closeness = max(0, 1 - distance)
                let shrink = shrinkFactor(for: distance)
                let width = (dotSize + (activeWidth - dotSize) * closeness) * shrink
                let height = dotSize * shrink

                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .overlay(
                        Capsule().fill(.primary).opacity(closeness)
                    )
                    .frame(width: width, height: height)
            }
        }
    }
    private func shrinkFactor(for distance: Double) -> CGFloat {
        let extra = max(0, distance - 2)
        return max(0.2, CGFloat(pow(0.7, extra)))
    }
}

