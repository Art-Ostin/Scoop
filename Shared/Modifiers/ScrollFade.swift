//
//  ScrollFade.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI

extension LinearGradient {
    // The base fade curve for any solid card/canvas color, opaque → clear.
    static func canvasFade(_ color: Color, startPoint: UnitPoint, endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.9), color.opacity(0.6), color.opacity(0.25), color.opacity(0.0)],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    static func appCanvasFade(startPoint: UnitPoint, endPoint: UnitPoint) -> LinearGradient {
        canvasFade(.appCanvas, startPoint: startPoint, endPoint: endPoint)
    }
    
    // Same alpha curve as appCanvasFade, scaled to the card's 8% wash so, layered on top of
    // appCanvasFade, it composites to exactly the base + tint — the real card background color.
    static func tintFade(_ color: Color, startPoint: UnitPoint, endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.08), color.opacity(0.072), color.opacity(0.048), color.opacity(0.02), color.opacity(0.0)],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    static func strongAppCanvasFade(startPoint: UnitPoint, endPoint: UnitPoint) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .appCanvas, location: 0.0),
                .init(color: .appCanvas.opacity(0.85), location: 0.15),
                .init(color: .appCanvas.opacity(0.75), location: 0.4),
                .init(color: .appCanvas.opacity(0.65), location: 0.6),
                .init(color: .appCanvas.opacity(0.5), location: 0.8),
                .init(color: .appCanvas.opacity(0.0), location: 1.0),
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

struct CustomScrollFade: ViewModifier {
    var isStrongFade: Bool = false
    
    let height: CGFloat
    let showFade: Bool
    let edge: VerticalEdge
    let isDetails: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: edge == .top ? .top : .bottom) {
            if showFade {
                Group {
                    if isStrongFade {
                        LinearGradient.strongAppCanvasFade(
                            startPoint: edge == .top ? .top : .bottom,
                            endPoint: edge == .top ? .bottom : .top
                        )
                    } else {
                        LinearGradient.appCanvasFade(
                            startPoint: edge == .top ? .top : .bottom,
                            endPoint: edge == .top ? .bottom : .top
                        )
                    }
                }
                .frame(height: height)
                .offset(y: isDetails ? 1 : 0) //So stroke on details is still always shown
                .allowsHitTesting(false)
                .padding(.horizontal, isDetails ? 1 : 0)
                .clipShape(.rect(cornerRadius: isDetails ? 30 : 0))
                .ignoresSafeArea(edges: edge == .top ? .top : .bottom) //Important this goes at end
            }
        }
    }
}

struct CustomHorizontalScrollFade: ViewModifier {
    // The card's base fill (`.appCanvas` by default) and tint wash (`.clear` outside the card),
    // so the fade dissolves into base + tint — the exact card background.
    @Environment(\.inviteCardBase) private var base
    @Environment(\.inviteCardTint) private var tint

    let width: CGFloat
    let showFade: Bool
    let fromLeading: Bool
    let isCardInvite: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: fromLeading ? .leading : .trailing) {
            if showFade {
                ZStack {
                    LinearGradient.canvasFade(
                        base,
                        startPoint: fromLeading ? .leading : .trailing,
                        endPoint: fromLeading ? .trailing : .leading
                    )
                    // Matches the card's wash on the same curve, so the fade blends into base + tint.
                    LinearGradient.tintFade(
                        tint,
                        startPoint: fromLeading ? .leading : .trailing,
                        endPoint: fromLeading ? .trailing : .leading
                    )
                }
                .frame(maxHeight: .infinity)
                .frame(width: width)
                .allowsHitTesting(false)
                .padding(.bottom, isCardInvite ? 10 : 0)
            }
        }
    }
}

extension View {
    func customScrollFade(height: CGFloat, showFade: Bool = true, edge: VerticalEdge = .top, isDetails: Bool = false, isStrong: Bool = false) -> some View {
        self.modifier(CustomScrollFade(isStrongFade: isStrong, height: height, showFade: showFade, edge: edge, isDetails: isDetails))
    }

    func customHorizontalScrollFade(width: CGFloat, showFade: Bool, fromLeading: Bool = true, isCardInvite: Bool = false) -> some View {
        self.modifier(CustomHorizontalScrollFade(width: width, showFade: showFade, fromLeading: fromLeading, isCardInvite: isCardInvite))
    }
}

//Glass ScrollFade



