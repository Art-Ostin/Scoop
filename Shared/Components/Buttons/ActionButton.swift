//
//  ActionButton.swift
//  ScoopTest
//
//  Created by Art Ostin on 18/06/2025.
//

import SwiftUI

struct ActionButton: View {

    var text: String
    var isValid: Bool = true
    var isInvite: Bool = false
    var cornerRadius: CGFloat = 24
    var showShadow: Bool = true
    var onTap: () -> Void
    
    var color: Color {
        isValid ? (isInvite ? Color.appGreen : Color.accent) : Color.grayBackground
    }

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.body(18, .bold))
                .padding(.horizontal, showShadow ? 24 : 36)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .buttonColourBackground(RoundedRectangle(cornerRadius: cornerRadius), tint: color)
                .padding(16) // expands the tappable region beyond the visible pill
                .background(Color.blue.opacity(0.3)) // TEST: visualizes the tap region
                .contentShape(Rectangle())
                .padding(-16)
        }
        .customButtonPressAndShadow(isValid && showShadow ? .high : nil, shadowColor: color)
        .disabled(!isValid)
    }
}




/*
 var body: some View {
     Button {
         if isValid {
             onTap()
         }
     } label: {
         Text(text)
             .font(.body(18, .bold))
             .padding(.horizontal, showShadow ? 24 : 36)
             .padding(.vertical, 12)
             .buttonStyle(.plain)
             .background(isValid ? (isInvite ? Color.appGreen : Color.accent) : Color.grayBackground)
             .foregroundStyle(.white)
             .cornerRadius(cornerRadius)
             .shadow(color: isValid ? .black.opacity(showShadow ? 0.2 : 0) : .clear, radius: 4, x: 0, y: 2)
     }
 }

 */
