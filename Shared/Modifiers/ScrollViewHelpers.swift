//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI


//MARK: Vertical Scroll default Layout

struct AppScrollView<Content: View>: View {

    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
        }
        .colorBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .scoopNavigationBarFonts()
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

//MARK: Track if User At Top of ScrollView

private struct IsAtTopOfScroll: ViewModifier {
    @Binding var isAtTop: Bool
    @State private var expandedInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentInsets.top
            } action: { _, inset in
                expandedInset = max(expandedInset, inset)
                isAtTop = inset >= expandedInset - 1
            }
            .onAppear {
                expandedInset = 0
                isAtTop = true
            }
    }
}

private struct isAtTopScrolling: ViewModifier {
    @Binding var isAtTop: Bool
    
    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y < 12 } action: { oldValue, newValue in
                isAtTop = newValue
            }

    }
}




//MARK:





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





extension View {
    func trackTopOfScroll(_ isAtTop: Binding<Bool>) -> some View {
        modifier(IsAtTopOfScroll(isAtTop: isAtTop))
    }
}



