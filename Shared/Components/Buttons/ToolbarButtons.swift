//
//  SettingsButton.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import SwiftUI


//To disappear when it is not at the top.
private struct ScrollTopTracker: ViewModifier {
    @Binding var isAtTop: Bool
    @State private var expandedInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentInsets.top } action: { _, inset in
                expandedInset = max(expandedInset, inset)
                isAtTop = inset >= expandedInset - 1
            }
            .onAppear {
                expandedInset = 0
                isAtTop = true
            }
    }
}

extension View {
    func trackTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(ScrollTopTracker(isAtTop: isAtTop))
    }
}
