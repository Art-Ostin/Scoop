//
//  FlowNavigation.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/07/2025.
//

import SwiftUI


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
                    ToolbarItem(placement: .topBarLeading) {
                        CustomBackButton()
                    }
                }
            }
    }
}

extension View {
    func flowNavigation() -> some View {
        modifier(FlowNavigation())
    }
}

