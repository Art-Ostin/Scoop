//
//  ActionButton2.swift
//  ScoopTest
//
//  Created by Art Ostin on 24/06/2025.
//

import SwiftUI

struct ActionButton2: View {
    
    let text: String
    
    var isValid: Bool
    
    let onTap: () -> Void
    
    var isSendInvite: Bool = true

    
    var body: some View {
        
        Button {
            onTap()
        } label: {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(isValid ? (isSendInvite ? Color.accent : Color.secondary) : Color.grayBackground)
                .foregroundStyle(.white)
                .cornerRadius(15)
                .shadow(color: isValid ? .black.opacity(0.175) : .clear , radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    ActionButton2(text: "Confirm & Send", isValid: true, onTap: {})
}
