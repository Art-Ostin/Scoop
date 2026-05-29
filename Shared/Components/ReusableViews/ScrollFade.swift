//
//  ScrollFade.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI

extension LinearGradient {
    static func appCanvasFade(startPoint: UnitPoint, endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(
            colors: [.appCanvas, .appCanvas.opacity(0.9), .appCanvas.opacity(0.6), .appCanvas.opacity(0.25), .appCanvas.opacity(0.0)],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

struct CustomScrollFade: ViewModifier {
    let height: CGFloat
    let showFade: Bool
    let edge: VerticalEdge
    let isDetails: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: edge == .top ? .top : .bottom) {
            if showFade {
                LinearGradient.appCanvasFade(
                    startPoint: edge == .top ? .top : .bottom,
                    endPoint: edge == .top ? .bottom : .top
                )
                .frame(height: height)
                .allowsHitTesting(false)
                .padding(.horizontal, isDetails ? 1 : 0)
                .clipShape(.rect(cornerRadius: isDetails ? 30 : 0))
                 .ignoresSafeArea(edges: edge == .top ? .top : .bottom) //Important this goes at end
            }
        }
    }
}

struct CustomHorizontalScrollFade: ViewModifier {
    let width: CGFloat
    let showFade: Bool
    let fromLeading: Bool
    let isCardInvite: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: fromLeading ? .leading : .trailing) {
            if showFade {
                LinearGradient.appCanvasFade(
                    startPoint: fromLeading ? .leading : .trailing,
                    endPoint: fromLeading ? .trailing : .leading
                )
                .frame(maxHeight: .infinity)
                .frame(width: width)
                .allowsHitTesting(false)
                .padding(.bottom, isCardInvite ? 10 : 0)
                .padding(.horizontal, isCardInvite ? 1 : 0)
            }
        }
    }
}

extension View {
    func customScrollFade(height: CGFloat, showFade: Bool, edge: VerticalEdge = .top, isDetails: Bool = false) -> some View {
        self.modifier(CustomScrollFade(height: height, showFade: showFade, edge: edge, isDetails: isDetails))
    }

    func customHorizontalScrollFade(width: CGFloat, showFade: Bool, fromLeading: Bool = true, isCardInvite: Bool = false) -> some View {
        self.modifier(CustomHorizontalScrollFade(width: width, showFade: showFade, fromLeading: fromLeading, isCardInvite: isCardInvite))
    }
}



struct ScrollNavBarVisibleKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
