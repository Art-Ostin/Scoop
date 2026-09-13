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

    ///Keeps the page on its slot while the pager itself changes width (see `PageHoldOnResize`). Off by default: a pager
    ///that swaps pages while it resizes is animating its own offset, and rounding it to a page would cut that swap
    var holdsPageOnResize: Bool = false

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
            .background { if holdsPageOnResize { PageHoldOnResize() } }
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

///A resizing pager re-lays its container-width pages at the new width on every frame of the resize, but `.paging` leaves
///the offset in points: page k drifts k × Δwidth off its slot and a strip of its neighbour shows (the respond card's photo,
///as the focused note takes the card full-bleed). Measured on the sim, SwiftUI re-seats nothing — not
///`defaultScrollAnchor(for: .sizeChanges)`, not an id-based `ScrollPosition`, and a `scrollTo` written mid-resize lands a
///whole resize late. So this watches the scroll view itself and puts the offset back on page × width in the same layout
///pass, every frame of the resize
private struct PageHoldOnResize: UIViewRepresentable {

    final class MarkerView: UIView {
        private var observations: [NSKeyValueObservation] = []
        private var width: CGFloat = 0
        private var contentWidth: CGFloat = 0
        private var heldPage: CGFloat? //The page a resize is holding, until a finger or a real page change moves the pager on

        override func didMoveToWindow() {
            super.didMoveToWindow()
            observations = []
            heldPage = nil
            guard window != nil else { return }
            var view: UIView? = superview
            while let current = view, !(current is UIScrollView) { view = current.superview }
            guard let scroll = view as? UIScrollView else { return }
            width = scroll.bounds.width
            contentWidth = scroll.contentSize.width
            //The bounds, not the content offset: a resize moves no offset, so the offset would never report it
            observations = [
                scroll.layer.observe(\.bounds) { [weak self, weak scroll] _, _ in
                    MainActor.assumeIsolated { if let scroll { self?.boundsChanged(scroll) } }
                },
                scroll.observe(\.contentSize) { [weak self, weak scroll] _, _ in
                    MainActor.assumeIsolated { if let scroll { self?.contentChanged(scroll) } }
                },
            ]
        }

        private func boundsChanged(_ scroll: UIScrollView) {
            let newWidth = scroll.bounds.width
            guard newWidth > 0 else { return }
            if scroll.isTracking { heldPage = nil } //Never under a finger: its release settles on a page of the new width
            guard newWidth != width else {
                //The origin alone: a swipe, a settle, or a clamp being corrected. Half a page is the pager going elsewhere
                if let page = heldPage, abs(scroll.contentOffset.x - page * width) > width / 2 { heldPage = nil }
                return
            }
            let oldWidth = width
            width = newWidth
            guard oldWidth > 0, !scroll.isTracking else { return }
            let page = heldPage ?? (scroll.contentOffset.x / oldWidth).rounded()
            heldPage = page
            hold(scroll, on: page)
        }

        private func contentChanged(_ scroll: UIScrollView) {
            guard scroll.contentSize.width != contentWidth else { return } //SwiftUI re-sets the same size on every pass
            contentWidth = scroll.contentSize.width
            guard let heldPage, !scroll.isTracking else { return }
            hold(scroll, on: heldPage) //A size landing late re-seats the clamp it caused
        }

        private func hold(_ scroll: UIScrollView, on page: CGFloat) {
            let target = page * width
            //The content width lands a frame behind the bounds, so the last page's slot overhangs it and the offset would
            //clamp short of it. Grown by that lag only, never a page: SwiftUI sets the same width on its next pass
            let shortfall = target + width - scroll.contentSize.width
            if shortfall > 0, shortfall < width { scroll.contentSize.width = target + width }
            if abs(scroll.contentOffset.x - target) > 0.01 { scroll.contentOffset.x = target }
        }
    }

    func makeUIView(context: Context) -> MarkerView {
        let view = MarkerView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: MarkerView, context: Context) {}
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


///Follows a drawer's reveal down the scroll it sits at the foot of, so what opened isn't left
///below the fold. Travels `distance`, or stops at the end of the content if less is left.
///Opening only — a collapse is already carried up by the content shrinking under the offset.
private struct DrawerNudge: ViewModifier {
    let isOpen: Bool
    let distance: CGFloat

    ///The caller's, not its own: a scroll view answers to ONE position, so a page with a second
    ///automatic move (History's jump back to the top on a new selection) drives the same one.
    @Binding var position: ScrollPosition

    @State private var geometry: ScrollGeometry?

    ///Measured on iOS 26: a nudge issued in the drawer's own transaction is clamped against the
    ///content as it stands BEFORE the drawer grows it — parked at the foot, that clamp is zero
    ///travel and the scroll never moves. 16ms and 33ms still land nothing; 50ms and up land the
    ///full distance. Double that floor, and still inside the `.expand` reveal, so the two read
    ///as one motion rather than a scroll after the fact.
    private static let settle = Duration.milliseconds(100)

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollGeometry.self) { $0 } action: { _, geo in
                geometry = geo //Read passively: driving the scroll from here would re-fire on every frame of the reveal
            }
            .task(id: isOpen) { await follow() } //Retoggling cancels the pending nudge with it
    }

    private func follow() async {
        guard isOpen else { return }
        try? await Task.sleep(for: Self.settle)
        guard !Task.isCancelled, isOpen, let geometry else { return }

        //contentInsets sit outside contentSize, so the top inset both floors the offset and is
        //the origin scrollTo(point:) measures its content-space y from
        let maxOffset = geometry.contentSize.height - geometry.containerSize.height - geometry.contentInsets.top
        let step = min(distance, maxOffset - geometry.contentOffset.y)
        guard step > 0 else { return } //Nothing below the fold: a short page shouldn't lurch

        withAnimation(.move) {
            position.scrollTo(point: CGPoint(x: 0, y: geometry.contentOffset.y + step + geometry.contentInsets.top))
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

    ///Applied where the scroll is BUILT, not where the drawer lives — modifiers reach the scroll
    ///views beneath them, so the flag has to be readable by the scroll's own owner. `position`
    ///is the one the caller already attached with `.scrollPosition`, so the nudge and any other
    ///programmatic move on that page speak through a single binding.
    func drawerNudge(isOpen: Bool, by distance: CGFloat, position: Binding<ScrollPosition>) -> some View {
        modifier(DrawerNudge(isOpen: isOpen, distance: distance, position: position))
    }

    func instantPressDelivery() -> some View {
        background(InstantPressDelivery())
    }

}
