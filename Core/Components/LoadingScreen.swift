//
//  LoadingScreen.swift
//  Scoop
//
//  Created by Art Ostin on 19/01/2026.
//

import SwiftUI
import Lottie

struct LoadingScreenAnimation: View {
    
    let text: String
    let fact = Facts.oneLineFacts.randomElement() ?? "Choose Life"
    
    var body: some View {
            VStack(spacing: 48){
                Text(text)
                    .font(.body(18, .bold))
                
                LottieView(animation: .named("ScoopLoading.json"))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .offset(y: -24)
                
                VStack(spacing: 8) {
                    Text("Random Astronomy Fact ")
                        .font(.body(17, .bold))
                    Text(fact)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
    }
}


#Preview {
    LoadingScreenAnimation(text: "Saving Changes")
}

struct LoadingScreen: ViewModifier {
    
    let isPresented: Bool
    let text: String
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack  {
                        Color.white.opacity(0.95).ignoresSafeArea()
                        LoadingScreenAnimation(text: text)
                    }
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
            .allowsHitTesting(!isPresented)
            .animation(.easeInOut(duration: 0.18), value: isPresented)
    }
}

extension View {
    func customLoadingScreen(isPresented: Bool, text: String = "Saving Changes") -> some View {
        modifier(LoadingScreen(isPresented: isPresented, text: text))
    }
}
