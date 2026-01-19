//
//  LoadingScreen.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI
import Lottie

struct LoadingScreen: View {
    var body: some View {
        LottieView(animation: .named("LoadingAnimation.json"))
    }
}

#Preview {
    LoadingScreen()
}
