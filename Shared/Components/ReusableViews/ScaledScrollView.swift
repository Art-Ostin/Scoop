//
//  ScaledScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 14/06/2026.
//

import SwiftUI

struct HorizontalScrollView<Content: View>: View {
    /// Width of the neighbouring page revealed on each side at rest. Implemented as a
    /// margin on the scroll *content* — it never touches a modifier on the views you
    /// pass in, so it can't shift their internal layout the way wrapping them in
    /// .padding would. (Unlike padding on the pages, it also stays inside the scroll
    /// view, so nothing around the scroll view moves.)
    var peek: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                content
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}

extension View {
    @ViewBuilder
    func horizontalScrollSlot(id: some Hashable, shrinkAnchor: UnitPoint? = nil) -> some View {
        let page = self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerRelativeFrame(.horizontal)
                .id(id)

            if let shrinkAnchor {
                page.pageScrollTransition(anchor: shrinkAnchor)
            } else {
                page
            }
    }
    
    func pageScrollTransition(anchor: UnitPoint, yOffset: CGFloat = 0) -> some View {
        scrollTransition(.interactive, axis: .horizontal) { content, phase in
            let progress = 1 - min(abs(phase.value), 1)
            let scale = 0.5 + progress * 0.5
            return content
                .scaleEffect(scale, anchor: anchor)
                .offset(y: (1 - progress) * yOffset)
        }
    }
}
