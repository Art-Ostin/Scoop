//
//  InfoText.swift
//  Scoop Test
//
//  Created by Art Ostin on 17/06/2026.
//

import SwiftUI

extension View {
    
    func infoText() -> some View {
        self
            .multilineTextAlignment(.leading)
            .font(.body(12, .regular))
            .foregroundStyle(Color.grayText)
            .lineSpacing(4)
    }
}

struct SmallInfoIcon: View {
    var size: CGFloat = 12
    var colour = Color(red: 0.8, green: 0.8, blue: 0.8)
    
    var body: some View {
        Image(systemName: "info.circle")
            .foregroundStyle(colour)
            .font(.body(size, .medium))
    }
}
