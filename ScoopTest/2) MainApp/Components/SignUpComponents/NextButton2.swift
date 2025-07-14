//
//  NextButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 17/06/2025.
//

import SwiftUI
import Observation

struct NextButton2: View {
    
    @Environment(AppState.self) private var appState

    
    let isEnabled: Bool
    
    let onInvalidTap: () -> Void
    
    let isSubmit: Bool
    
    init(isEnabled: Bool, onInvalidTap: @escaping () -> Void, isSubmit: Bool = false) {
        self.isEnabled = isEnabled
        self.onInvalidTap = onInvalidTap
        self.isSubmit = isSubmit
    }
    
    
    var body: some View {
        Button {
            if isEnabled {
                if isSubmit, case .onboarding = appState.stage {
                    appState.stage = .limitedAccess
                } else if isSubmit, case .profileSetup = appState.stage {
                    appState.stage = .main
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.nextStep()
                    }
                }
            } else {
                onInvalidTap()
            }
        } label: {
            if isSubmit {
                Image(systemName: "checkmark")
                    .frame(width: 50, height: 50, alignment: .center)
                    .background(isEnabled ? Color.accent : Color.grayBackground)
                    .foregroundStyle(.white)
                    .font(.system(size: 24, weight: .bold))
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Image("ForwardArrow")
                    .frame(width: 69, height: 44, alignment: .center)
                    .background( isEnabled ? Color.accent : Color(red: 0.93, green: 0.93, blue: 0.93))
                    .cornerRadius(33)
                    .shadow(color: isEnabled ? .black.opacity(0.25) : .clear , radius: 2, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.2), value: isEnabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    NextButton2(isEnabled: true, onInvalidTap: {}, isSubmit: false)
        .environment(AppState())
}
