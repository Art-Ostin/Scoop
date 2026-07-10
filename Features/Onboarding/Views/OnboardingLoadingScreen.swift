//
//  LoadingScreenOnboarding.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI
import Lottie

struct OnboardingLoadingScreen: View {
    
    //Local view state
    @State private var textIndex: Int = 0
    private let facts = Facts.oneLineFacts


    var body: some View {
        VStack(spacing: Spacing.xxl){
            Text("Creating Profile")
                .font(.body(20, .bold))
            
            LottieView(animation: .named("ScoopLoading.json"))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .offset(y: -24)
            
            VStack(spacing: Spacing.lg) {
                Text("Did you know")
                    .font(.body(17, .bold))
                Text(facts[textIndex])
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.margin)
            }
        }
        .padding(.horizontal)
        .task(id: textIndex) {
            try? await Task.sleep(for: .seconds(4))
            if textIndex < 3 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    textIndex += 1
                }
            }
        }
    }
}

#Preview {
    OnboardingLoadingScreen()
}
