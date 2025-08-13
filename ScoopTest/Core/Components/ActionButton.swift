//
//  ActionButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {
    
    var text: String
    var isValid: Bool
    var isInvite: Bool
    var onTap: () -> Void
    var cornerRadius: CGFloat
    
    init(isValid: Bool = true, text: String, isInvite: Bool = false, cornerRadius: CGFloat = 24, onTap: @escaping () -> Void) {
        self.isValid = isValid
        self.text = text
        self.onTap = onTap
        self.cornerRadius = cornerRadius
        self.isInvite = isInvite
    }
    
    var body: some View {
        Button {
            if isValid {
                onTap()
            }
        } label: {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isValid ? (isInvite ? Color.defaultGreen : Color.accent) : Color.grayBackground)
                .foregroundStyle(.white)
                .cornerRadius(cornerRadius)
                .shadow(color: isValid ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
        }
    }
}
#Preview{
    ActionButton(text: "Login / Sign Up", onTap: {})
}
