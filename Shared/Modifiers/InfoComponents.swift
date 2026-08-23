//
//  InfoComponents.swift
//  Scoop
//
//  Created by Art Ostin on 17/06/2026.
//

import SwiftUI

extension View {
    
    func infoText() -> some View {
        self
            .multilineTextAlignment(.leading)
            .font(.body(12, .regular))
            .foregroundStyle(Color.textTertiary)
            .lineSpacing(4)
    }
}

struct SmallInfoIcon: View {
    var size: CGFloat = 12
    var colour = Color.textPlaceholder
    
    var body: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(colour)
            .font(.body(size, .medium))
    }
}

//An explanation that rolls open under a heading, its top gap revealed with it
struct RevealingInfoText: View {
    let text: String
    let isOpen: Bool
    
    var body: some View {
        Text(text)
            .infoText()
            .padding(.top, Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .drawer(isOpen: isOpen)
    }
}
