//
//  ScrollFade.swift
//  Scoop
//
//  Created by Art Ostin on 18/01/2026.
//

import SwiftUI

struct CustomScrollFade: ViewModifier {
    
    let height: CGFloat
    let showFade: Bool
    let edge: VerticalEdge
    
    
    func body(content: Content) -> some View {
        let isDetails = height == 80
        let isLanguage = height == 48
        
        let alignment: Alignment = edge == .top ? .top : .bottom
        let safeAreaEdges: Edge.Set = edge == .top ? .top : .bottom
        let startPoint: UnitPoint = edge == .top ? .top : .bottom
        let endPoint: UnitPoint = edge == .top ? .bottom : .top
        content
            .overlay(alignment: alignment) {
                if showFade {
                    LinearGradient(
                        colors: [.background, .background.opacity(0.9), .background.opacity(0.6), .background.opacity(0.25), .background.opacity(0.0)],
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .cornerRadius(isLanguage ? 0 : 30)
                        .offset(y: isDetails ? 0.5 : 0)
                        .ignoresSafeArea(edges: safeAreaEdges)
                        .padding(.horizontal, isDetails ? 1 : 0)
                        .allowsHitTesting(false)
                        .offset(y: edge == .bottom ? 36 : 0)
                }
            }
    }
}
extension View {
    func customScrollFade(height: CGFloat, showFade: Bool, edge: VerticalEdge = .top) -> some View {
        self.modifier(CustomScrollFade(height: height, showFade: showFade, edge: edge))
    }

    
    func customHorizontalScrollFade(width: CGFloat, showFade: Bool, fromLeading: Bool = true, isCardInvite: Bool = false) -> some View {
        self.overlay(alignment: fromLeading ? .leading : .trailing) {
            if showFade {
                LinearGradient(
                    colors: [.background, .background.opacity(0.9), .background.opacity(0.6), .background.opacity(0.25), .background.opacity(0.0)],
                    startPoint: fromLeading ? .leading : .trailing,
                    endPoint: fromLeading ? .trailing : .leading
                )
                .frame(maxHeight: .infinity)
                .frame(width: width)
                .allowsHitTesting(false)
                .padding(.bottom, isCardInvite ? 10 : 0)
                .padding(.horizontal,isCardInvite ? 1 : 0)
            }
        }
    }
}
