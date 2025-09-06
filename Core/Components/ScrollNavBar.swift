//
//  NavBarTest.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct ScrollNavBar: View {
    
    let title: String
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .white.opacity(1.0), location: 0.0),
                    .init(color: .white.opacity(0.5), location: 0.6),
                    .init(color: .white.opacity(0.0), location: 1.0)
                ]),
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
            
                Text(title)
                    .font(.body(17, .bold))
                
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
}
