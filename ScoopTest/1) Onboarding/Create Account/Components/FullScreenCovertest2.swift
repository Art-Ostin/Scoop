//
//  FullScreenCovertest2.swift
//  ScoopTest
//
//  Created by Art Ostin on 21/07/2025.
//

import SwiftUI

struct FullScreenCovertest2: View {
    
    @State var isOnboarding: Bool = true
    
    var body: some View {
        
        ZStack {
            if !isOnboarding {
                ScreenTestC()
            } else {
                ScreenTestA(isOnboarding: $isOnboarding)
            }
        }
    }
}

#Preview {
    FullScreenCovertest2()
}

struct ScreenTestA: View {
    @Binding var isOnboarding: Bool

    @State var showContainer: Bool = false
    var body: some View {
        ZStack {
            Color(.blue).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Hello There")
                    .font(.largeTitle)
                Button("Go Back") {showContainer = true}
            }
            .fullScreenCover(isPresented: $showContainer) {
                withAnimation {
                    ScreenTestB(isOnboarding: $isOnboarding, showContainer: $showContainer)
                }
            }
        }
    }
}

struct ScreenTestB: View {
    @Binding var isOnboarding: Bool
    
    @Binding var showContainer: Bool

    var body: some View {
        ZStack {
            Color(.orange).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Hello There")
                    .font(.largeTitle)
                Button("Complete") {withAnimation(.easeInOut(duration: 1)) {
                    showContainer = false
                    isOnboarding = false
                }}
            }
        }
    }
}

struct ScreenTestC: View {
    
    var body: some View {
        ZStack {
            Color(.green).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Hello There")
                    .font(.largeTitle)
            }
        }
    }
}
