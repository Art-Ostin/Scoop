//
//  CardFlip.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

struct CardFlipContainer<FrontCard: View, BackCard: View>: View {
    @Binding var showBack: Bool
    
    @ViewBuilder let frontCard: FrontCard
    @ViewBuilder let backCard: BackCard
    
    var body: some View {
        ZStack {
            frontCard
                .opacity(showBack ? 0 : 1)
                .allowsHitTesting(!showBack)
                .zIndex(showBack ? 0 : 1)

            backCard
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
                .allowsHitTesting(showBack)
                .zIndex(showBack ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y:1, z:0))
        .animation(.snappy, value: showBack)
    }
}
