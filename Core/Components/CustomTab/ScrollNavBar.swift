//
//  NavBarTest.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct ScrollNavBar: View {
    let title: String
    
    let topSafeArea: CGFloat?
    
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white,                 // solid at the very top
                    .white.opacity(0.98),
                    .white.opacity(0.90),
                    .white.opacity(0.65),
                    .white.opacity(0.35),
                    .white.opacity(0.0)     // fully transparent at the bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            Text(title)
                .font(.body(17, .bold))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: (topSafeArea ?? 0) + 48)
    }
}
