//
//  NextButton2.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/07/2025.
//

import SwiftUI

struct NextButton: View {
    @Environment(\.flowMode) private var mode
    
    let isEnabled: Bool
    let onTap: () -> Void
    
    @State private var didTap = false

    private var actuallyEnabled: Bool {
        isEnabled && !didTap
    }
    
    var body: some View {
        Image("ForwardArrow")
            .frame(width: 69, height: 44, alignment: .center)
            .background(isEnabled ? Color.accent : Color.grayBackground)
            .cornerRadius(33)
            .shadow(color: isEnabled ? .black.opacity(0.2) : .clear , radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .onTapGesture {
                guard actuallyEnabled else {return}
                didTap = true
                withAnimation{
                    if case .onboarding(_, let advance) = mode {
                        advance()
                    }
                    onTap()
                }
            }
    }
}

#Preview {
    NextButton(isEnabled: false, onTap: {})
}

struct SubmitButton: View {
    
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Image(systemName: "checkmark")
            .font(.body(22, .bold))
            .background(
                Circle()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(isEnabled ? Color.accent : Color.grayBackground)
                    .shadow(color: isEnabled ? .black.opacity(0.25) : .clear , radius: 2, x: 0, y: 2)
            )
            .foregroundStyle(Color.white)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

