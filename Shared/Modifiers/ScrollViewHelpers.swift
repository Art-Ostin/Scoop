//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI
import UIKit

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

private struct InstantPressDelivery: UIViewRepresentable {

    final class MarkerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var v: UIView? = superview
            while let cur = v, !(cur is UIScrollView) { v = cur.superview }
            (v as? UIScrollView)?.delaysContentTouches = false
        }
    }

    func makeUIView(context: Context) -> MarkerView {
        let v = MarkerView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: MarkerView, context: Context) {}
}

extension View {

    func isAtTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(IsAtTopOfScroll(isAtTop: isAtTop))
    }
    
    func trackScrollProgress(scrollProgress: Binding<Double>) -> some View {
        modifier(TrackScrollProgess(scrollProgress: scrollProgress))
    }
    
    /// Place inside a ScrollView's content: buttons in that scroll press on
    /// touch-down (the ProfileCard feel) instead of after the system delay.
    func instantPressDelivery() -> some View {
        background(InstantPressDelivery())
    }
}
