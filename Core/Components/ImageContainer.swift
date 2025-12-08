//
//  ImageContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 07/08/2025.
//

import SwiftUI

struct ImageModifier: ViewModifier {
    

    @State private var measuredWidth: CGFloat?
    let padding: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: measuredWidth.map { max($0, 0) })
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .measure(key: NewImageSizeKey.self) { ($0.size.width - padding) }
            .onPreferenceChange(NewImageSizeKey.self) { measuredWidth = $0}
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
