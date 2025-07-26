//
//  ActionButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {
    
    var text: String
    var onTap: () -> Void
    var isAuthorised: Bool
    
    init(isAuthorised: Bool = true, text: String, onTap: @escaping () -> Void) {
        self.isAuthorised = isAuthorised
        self.text = text
        self.onTap = onTap
    }
    
    var body: some View {
        
        Button {
            if isAuthorised {
                onTap()
            }
        } label: {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isAuthorised ? Color.accent : Color.grayBackground)
                .foregroundStyle(.white)
                .cornerRadius(24)
                .shadow(color: isAuthorised ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
        }
    }
}
#Preview{
    ActionButton(text: "Login / Sign Up", onTap: {})
}
