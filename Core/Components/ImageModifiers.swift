//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI



struct ImageModifier: ViewModifier {
    
    let size: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    func defaultImage(_ size: CGFloat, _ radius: CGFloat = 18) -> some View { modifier(ImageModifier(size: size, radius: radius)) }
}
