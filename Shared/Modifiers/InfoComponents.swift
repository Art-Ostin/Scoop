//
//  InfoText.swift
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
