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
        //1. If details diffferent behaviour
        let isDetails = height == 80

        content
            .overlay(alignment: edge == .top ? .top : .bottom) {
                if showFade {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask {
                            LinearGradient(
                                colors: [.clear, .blue.opacity(0.9), .blue.opacity(0.6), .blue.opacity(0.25), .blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(height: height)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                    
                        //Different behaviour for scrollbehaviour in details
                        .padding(.horizontal, isDetails ? 1 : 0)
                        .offset(y: isDetails ? 0.5 : 0)
                        .cornerRadius(isDetails ? 30 : 0)
                }
            }
    }
}


//Horizontal ScrollFade
extension View {
    func customScrollFade(height: CGFloat, showFade: Bool, edge: VerticalEdge = .top) -> some View {
        self.modifier(CustomScrollFade(height: height, showFade: showFade, edge: edge))
    }


    func customHorizontalScrollFade(width: CGFloat, showFade: Bool, fromLeading: Bool = true, isCardInvite: Bool = false) -> some View {
        self.overlay(alignment: fromLeading ? .leading : .trailing) {
            if showFade {
                LinearGradient(
                    colors: [.appCanvas, .appCanvas.opacity(0.9), .appCanvas.opacity(0.6), .appCanvas.opacity(0.25), .appCanvas.opacity(0.0)],
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

