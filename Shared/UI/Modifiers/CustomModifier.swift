//
//  CustomModifier.swift
//  Scoop
//
//  Created by Art Ostin on 06/12/2025.
//

import SwiftUI


struct GeoPreferenceKey<Key: PreferenceKey>: ViewModifier {
    let transform: (GeometryProxy) -> Key.Value
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: Key.self,
                                    value: transform(geo))
                }
            )
    }
}

extension View {
    func measure<Key: PreferenceKey>(key: Key.Type = Key.self, value transform: @escaping (GeometryProxy) -> Key.Value) -> some View {
        modifier(GeoPreferenceKey<Key>(transform: transform))
    }
}

