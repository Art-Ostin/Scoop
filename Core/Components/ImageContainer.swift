//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI

struct ImageModifier: ViewModifier {
    
    @State var imageSize: CGFloat = 0
    let padding: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .frame(width: imageSize, height: imageSize)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .measure(key: NewImageSizeKey.self) { $0.frame(in: .global).width}
            .onPreferenceChange(NewImageSizeKey.self) { screenWidth in
                imageSize = screenWidth - padding
            }
    }
}

extension View {
    func scoopImage(_ padding: CGFloat,_ radius: CGFloat = 18) -> some View {
        modifier(ImageModifier(padding: padding, radius: radius))
    }
    
    func defaultImage(_ padding: CGFloat,_ radius: CGFloat = 18) -> some View {
        modifier(ImageModifier(padding: padding, radius: radius))
    }
}

struct NewImageSizeKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
