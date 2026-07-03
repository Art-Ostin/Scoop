//
//  ActionButton.swift
//  Scoop
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {

    let text: String
    var isValid: Bool = true
    var isInvite: Bool = false
    var showShadow: Bool = true //Don't want shadow on action button for cards
    var cornerRadius: CGFloat = 24 //Effectively a capsule
    var hPadding: CGFloat = 36
    let onTap: () -> Void
    
    var color: Color {
        isValid ? (isInvite ? Color.successGreen : Color.accent) : Color.fillGray
    }
    
    var shadow: Elevation? { isValid && showShadow ? .high : nil}

    var body: some View {
        ScoopButton(style: .tinted(color, shadow: shadow), shape: .rect(cornerRadius: cornerRadius, style: .continuous), action: onTap) {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, hPadding)
                .frame(height: text == "Send Invite" ? 47 : 44) 
        }
        .disabled(!isValid)
    }
}
