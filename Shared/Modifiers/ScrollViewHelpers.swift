//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI
import UIKit

struct HorizontalScrollView<Content: View>: View {
    @Binding var progress: Double

    var alignment: VerticalAlignment = .center

    var position: Binding<ScrollPosition>? = nil

    var peek: CGFloat = 0

    @ViewBuilder var content: Content

    @ViewBuilder
    var body: some View {
        if let position {
            pager
                .scrollPosition(position)
        } else {
            pager
        }
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(alignment: alignment, spacing: 0) {
                content
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .trackScrollProgress(scrollProgress: $progress)
        .padding(.horizontal, peek) //The pitch IS the pager's width, so the peek is carved out of it
        .peekClipDisabled(peek > 0)
    }
}

private extension View {

    ///Only ever DISABLES clipping: writing `false` here would beat a call site's own
    ///`.scrollClipDisabled()` applied from outside, since the innermost value wins.
    @ViewBuilder
    func peekClipDisabled(_ disabled: Bool) -> some View {
        if disabled { scrollClipDisabled() } else { self }
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


///How far the large title has risen from its resting position (0 at the top of the scroll,
///NEGATIVE while rubber-banding down). The system title scrolls 1:1 with the content — the
///damping is already in contentOffset — so an overlay offset by -travel rides it both ways.
private struct TitleTravel: ViewModifier {
    @Binding var travel: CGFloat
    @State private var expandedInset: CGFloat = 0        // fully-expanded (large-title) inset
    
    private struct Geo: Equatable { var offsetY, insetTop: CGFloat }
    
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Geo.self) { geo in
                Geo(offsetY: geo.contentOffset.y, insetTop: geo.contentInsets.top)
            } action: { _, g in
                expandedInset = max(expandedInset, g.insetTop)   // learn the expanded inset
                travel = g.offsetY + expandedInset
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
            //EVERY scroll ancestor, not just the nearest: the nearest is often not the one that
            //would delay the touch — the invite card's time row sits inside ConfirmTimeAndPlace's
            //own (disabled) inner pager, while the delay comes from the invites pager above it.
            var v: UIView? = superview
            while let cur = v {
                (cur as? UIScrollView)?.delaysContentTouches = false
                v = cur.superview
            }
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

    func titleTravel(_ travel: Binding<CGFloat>) -> some View {
        modifier(TitleTravel(travel: travel))
    }

    func trackScrollProgress(scrollProgress: Binding<Double>) -> some View {
        modifier(TrackScrollProgess(scrollProgress: scrollProgress))
    }

    func instantPressDelivery() -> some View {
        background(InstantPressDelivery())
    }

}
