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
    var activeWidth: CGFloat = 22
    var spacing: CGFloat = 8
    var activeColor: Color = .primary
    var inactiveColor: Color = Color.grayPlaceholder.opacity(0.25)

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { i in
                let distance = abs(progress - Double(i))
                let closeness = max(0, 1 - distance)
                let shrink = shrinkFactor(for: distance)
                let width = (dotSize + (activeWidth - dotSize) * closeness) * shrink
                let height = dotSize * shrink

                Capsule()
                    .fill(inactiveColor)
                    .overlay(
                        Capsule().fill(activeColor).opacity(closeness)
                    )
                    .frame(width: width, height: height)
            }
        }
    }

    private func shrinkFactor(for distance: Double) -> CGFloat {
        let extra = max(0, distance - 2)
        return max(0.2, CGFloat(pow(0.5, extra)))
    }
}

#Preview("Continuous (scroll-driven)") {
    @Previewable @State var progress: Double = 0

    VStack(spacing: 48) {
        AnimatedPageIndicator(count: 5, progress: progress)

        Slider(value: $progress, in: 0...4)
            .padding(.horizontal, 40)

        Text("progress: \(progress, specifier: "%.2f")")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Discrete (tap to change)") {
    @Previewable @State var selection: Int = 0
    let count = 5

    VStack(spacing: 48) {
        AnimatedPageIndicator(count: count, progress: Double(selection))
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selection)

        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { i in
                Button("\(i + 1)") { selection = i }
                    .buttonStyle(.bordered)
            }
        }
    }
    .padding()
}
