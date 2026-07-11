//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI

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

struct ContainerScrollView<Content: View>: View {
    
    
    var body: some View {
        
    }
}




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



