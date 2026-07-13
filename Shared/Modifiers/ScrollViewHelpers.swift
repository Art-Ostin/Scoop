//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI


//MARK: Vertical Scroll default Layout

struct AppScrollView<Content: View>: View {

    let title: String
    var largeTitleSize: CGFloat = 32       // Events passes 26 for its longer "Meeting {name}" title
    var isAtTop: Binding<Bool>? = nil       // opt-in scroll-top hook (Meet's InfoButton); a no-op otherwise
    let content: Content

    init(title: String,
         largeTitleSize: CGFloat = 32,
         isAtTop: Binding<Bool>? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.largeTitleSize = largeTitleSize
        self.isAtTop = isAtTop
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
        }
        .isAtTopOfScroll(isAtTop ?? .constant(false))
        .colorBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .scoopNavigationBarFonts(largeTitleSize: largeTitleSize)
    }
}

extension View {
    //Standard tab-content insets: gap below the large title, clearance above the tab bar / floating chrome.
    func tabContentInsets() -> some View {
        padding(.top, Spacing.titlePadding)
        .padding(.bottom, Spacing.clearance)
    }
}

//MARK: Horizontal Scroll default Layout
struct PagerScrollView<Content: View>: View {
    var peek: CGFloat = 0
    var progress: Binding<Double>? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                content
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .pagedScroll(progress: progress)
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

extension View {
    func isAtTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(IsAtTopOfScroll(isAtTop: isAtTop))
    }
}




extension View {
    @ViewBuilder
    func pagedScroll(progress: Binding<Double>? = nil) -> some View {
        let base = self
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        
        if let progress {
            base.trackScrollProgress(scrollProgress: progress)
        } else {
            base
        }
    }
}


extension View {
    
    func trackScrollProgress(scrollProgress: Binding<Double>) -> some View {
        self
            .onScrollGeometryChange(for: Double.self) { geo in
                min(geo.contentOffset.x / geo.containerSize.width, 0)
            } action: { _, newValue in
                scrollProgress.wrappedValue = newValue
            }
    }
}
