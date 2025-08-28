//
//  FlowNavigation.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI

//File Creates an environment to track for the "Edit Screens" if i am on onboarding or in the app.
enum FlowMode {
    case onboarding(step: Int, advance: () -> Void)
    case profile
}

struct FlowModeKey: EnvironmentKey {
    static var defaultValue: FlowMode = .profile
}

extension EnvironmentValues {
    var flowMode: FlowMode {
        get { self[FlowModeKey.self]}
        set { self[FlowModeKey.self] = newValue }
    }
}

struct FlowNavigation: ViewModifier {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.flowMode) private var mode
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .toolbar {
                switch mode {
                case .onboarding(_, _):
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("SAVE") { dismiss() }
                            .font(.body(12))
                            .foregroundStyle(Color.grayText)
                    }
                case .profile:
                    ToolbarItem(placement: .topBarLeading) { NavButton() }
                }
            }
    }
}

extension View {
    func flowNavigation() -> some View {
        modifier(FlowNavigation())
    }
}

