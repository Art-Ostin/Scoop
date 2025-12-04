//
//  CustomPreferenceKeys.swift
//  Scoop
//
//  Created by Art Ostin on 03/12/2025.
//


import SwiftUI


struct ReportBottom: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ReportBottomModifier: ViewModifier {
    let coordinateSpace: String
    
    func body(content: Content) -> some View {
        content
            .background (
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ReportBottom.self, value: geo.frame(in: .named(coordinateSpace)).maxY)
                }
            )
    }
}

extension View {
    func reportBottom(_ coordinateSpace: String) -> some View {
        modifier(ReportBottomModifier(coordinateSpace: coordinateSpace))
    }
}
