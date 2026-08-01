//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI

//MARK: Horizontal Scroll default Layout
struct HorizontalScrollView<Content: View>: View {
    @Binding var progress: Double

    //How pages of unequal height sit against each other
    var alignment: VerticalAlignment = .center

    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: alignment, spacing: 0) {
                content
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .trackScrollProgress(scrollProgress: $progress)
    }
}







private struct IsAtTopOfScroll: ViewModifier {
    @Binding var isAtTop: Bool
    @State private var expandedInset: CGFloat = 0        // fully-expanded (large-title) inset
    
    private struct Geo: Equatable { var offsetY, insetTop: CGFloat }
    
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Geo.self) { geo in
                Geo(offsetY: geo.contentOffset.y, insetTop: geo.contentInsets.top)
            } action: { _, g in
                expandedInset = max(expandedInset, g.insetTop)   // learn the expanded inset
                isAtTop = g.offsetY <= -expandedInset + 1        //Geometry: 1pt float-jitter tolerance
            }
    }
}


private struct TrackScrollProgess: ViewModifier {
    @Binding var scrollProgress: Double
    
    func body(content: Content) -> some View {
        content
        .onScrollGeometryChange(for: Double.self) { geo in
            geo.containerSize.width > 0 ? max(geo.contentOffset.x / geo.containerSize.width, 0) : 0
        } action: { _, newValue in
            scrollProgress = newValue
        }
    }
}


extension View {
    
    func isAtTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(IsAtTopOfScroll(isAtTop: isAtTop))
    }
    
    func trackScrollProgress(scrollProgress: Binding<Double>) -> some View {
        modifier(TrackScrollProgess(scrollProgress: scrollProgress))
    }
}
