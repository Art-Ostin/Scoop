//
//  ViewMeasurements.swift
//  Scoop
//
//  Created by Art Ostin on 28/09/2025.
//

import SwiftUI

//struct MainImageBottomValue: PreferenceKey {
//    static let defaultValue: CGFloat = 0
//    
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = max(value, nextValue())
//    }
//}

struct ScrollImageBottomValue: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    
    func reportBottom<Key: PreferenceKey>(in space: String, as key: Key.Type) -> some View where Key.Value == CGFloat {
        background (
            GeometryReader { g in
                Color.clear
                    .preference(key: key, value: g.frame(in: .named(space)).maxY)
            }
        )
    }
}
