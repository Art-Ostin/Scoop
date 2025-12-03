//
//  CustomPreferenceKeys.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//

import SwiftUI

struct ViewBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


extension View {
    func reportBottom(in space: CoordinateSpace = .global) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: ViewBottomPreferenceKey.self,
                        value: proxy.frame(in: space).maxY
                    )
            }
        )
    }
}
