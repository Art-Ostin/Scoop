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
    
    func body(content: Content) -> some View {
        let isDetails = height == 80
        content
            .overlay(alignment: .top){
                if showFade {
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9), .white.opacity(0.6), .white.opacity(0.25), .white.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .cornerRadius(30)
                        .offset(y: isDetails ? 0.5 : 0)
                        .ignoresSafeArea()
                        .padding(.horizontal, isDetails ? 1 : 0)
                }
            }
    }
}
extension View {
    func customScrollFade(height: CGFloat, showFade: Bool) -> some View {
        self.modifier(CustomScrollFade(height: height, showFade: showFade))
    }
}
