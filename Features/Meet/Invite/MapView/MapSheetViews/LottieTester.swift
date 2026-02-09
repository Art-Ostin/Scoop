//
//  LottieTester.swift
//  Scoop
//
//  Created by Art Ostin on 09/02/2026.
//

import SwiftUI
import Lottie

struct LottieTester: View {
    var body: some View {
        LottieView(animation: .named("ModernMiniLoader.json"))
            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .foregroundStyle(Color.accent)

    }
}

#Preview {
    LottieTester()
}
