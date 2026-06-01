//
//  ActionButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {

    let text: String
    var isValid: Bool = true
    var isInvite: Bool = false
    var cornerRadius: CGFloat = 24
    var showShadow: Bool = true
    let onTap: () -> Void
    
    var color: Color {
        isValid ? (isInvite ? Color.appGreen : Color.accent) : Color.grayBackground
    }

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, showShadow ? 24 : 36)
                .padding(.vertical, 12)
                .buttonBackground(RoundedRectangle(cornerRadius: cornerRadius), color: color)
        }
        .shrinkButton(shadow: isValid && showShadow ? .medium : nil, shadowColor: color)
        .disabled(!isValid)
    }
}
