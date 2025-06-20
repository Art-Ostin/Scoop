//
//  AppState.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.

import SwiftUI

@Observable class AppState {
    
    enum state {
        case signUp
        case onboarding (index: Int)
        case limitedAccess
        case profileSetup (index: Int)
        case main
    }
    
     var stage: state = .signUp
    
    func nextStep() {
        if case .onboarding(let current) = stage {
            stage = .onboarding(index: current + 1)
        } else if case .profileSetup(let current) = stage {
            stage = .onboarding(index: current + 1)
        }
    }
}

struct RootView : View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            switch appState.stage {
            case .signUp:
                SignUpView()
            case .onboarding:
                OnboardingContainer()
                    .transition(.move(edge: .bottom))
            case .limitedAccess:
                LimitedAccessView()
            case .profileSetup:
                CreateProfileContainer()
                    .transition(.move(edge: .bottom))
            case .main:
                AppContainer()
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .offWhite()
}
