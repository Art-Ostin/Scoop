//
//  AppScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 29/05/2026.

import SwiftUI


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





 struct AppScrollView<Content: View>: View {
         
     // Inputs
      let title: String
      var path: Binding<NavigationPath>? = nil
      @ViewBuilder let content: Content

      // Local state - either take a path as binding if needed or pass one in here
      @State private var localPath = NavigationPath()
     
     var body: some View {
         NavigationStack(path: path ?? $localPath) {
             ScrollView {
                 content
             }
             .colorBackground()
             .navigationTitle(title)
             .scoopNavigationBarFonts()
             .scrollIndicators(.hidden)
         }
     }
 }
 
