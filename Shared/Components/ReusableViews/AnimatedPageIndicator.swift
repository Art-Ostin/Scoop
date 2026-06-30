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
    
    var isInviteIndicator: Bool { inactiveDotSize == 5 }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { i in
                let distance = abs(progress - Double(i))
                let closeness = max(0, 1 - distance)
                let shrink = shrinkFactor(for: distance)

                let height = (inactiveDotSize + (dotSize - inactiveDotSize) * closeness) * shrink
                let width = (inactiveDotSize + (activeWidth - inactiveDotSize) * closeness) * shrink

                Capsule()
                    .fill(Color.grayPlaceholder)
                    .opacity(isInviteIndicator ? 1 - closeness : 1)
                    .overlay(
                        Group {
                            if isInviteIndicator {
                                Capsule()
                                    .strokeBorder(Color(white: 0.5), lineWidth: 1.3)
                            } else {
                                Capsule()
                                    .fill(.primary)
                            }
                        }
                        .opacity(closeness)
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

extension View {
    
    func trackScrollProgress(scrollProgress: Binding<Double>) -> some View {
        self
            .onScrollGeometryChange(for: Double.self) { geo in
                let width = geo.containerSize.width
                return width > 0 ? geo.contentOffset.x / width : 0
            } action: { _, newValue in
                scrollProgress.wrappedValue = newValue
            }
    }
}
