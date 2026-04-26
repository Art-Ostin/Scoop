//
//  LoadingScreenOnboarding.swift
//  Scoop
//
//  Created by Art Ostin on 21/01/2026.
//

import SwiftUI
import Lottie

struct OnboardingLoadingScreen: View {
    
    @State private var textIndex: Int = 0
    
    let text: [String] = [
        "99.973% of an atom’s mass is packed into its nucleus",
        "The nucleus is ~55,000× smaller than the atom",
        "The sun",
        "In a neutron star, gravity pushes nuclei together until there’s almost no empty space",
        "Thus, a teaspoon of matter from a neutron star is equivalent to 4000 Olympic Swimming Pools, a teaspoon!"
    ]
    
    let facts = Facts.oneLineFacts
    
    
    var body: some View {
        VStack(spacing: 48){
            Text("Creating Profile")
                .font(.body(20, .bold))
            
            LottieView(animation: .named("ScoopLoading.json"))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .offset(y: -24)
            
            VStack(spacing: 24) {
                Text("Did you know")
                    .font(.body(17, .bold))
                Text(facts[textIndex])
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
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
