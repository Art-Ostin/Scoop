//
//  CustomSubtitle.swift
//  Scoop
//
//  Created by Art Ostin on 15/09/2026.
//

import SwiftUI

extension View {
    func customSubtitle(lineSpacing: CGFloat = 6) -> some View {
        self
            .font(.body(13, .regular))
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .kerning(0.312)
            .lineSpacing(lineSpacing)
        
    }
}
