//
//  TabScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.

import SwiftUI


//Used for TabScrollView, and EditProfile and Settings View screens
struct PageScrollView<Content: View>: View {
    
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        ScrollView {
            content
        }
        .navigationTitle(title)
        .colorBackground()
        .padding(.top, Spacing.titlePadding)
        .padding(.bottom, Spacing.clearance)
    }
}

//The reusable structure of all TabViews extracted
struct TabScrollView<Content: View>: View {
    let type: AppTab
    let showEmptyView: Bool
    var name: String = ""
    @ViewBuilder let content: Content
    
    
    var titleSize: CGFloat {type == .events && !showEmptyView ? 28 : 32}
    var title: String { type.title(name: name, isEmpty: showEmptyView)}

    var body: some View {
        
        PageScrollView(title: title) {
            if showEmptyView {
                type.placeholderView()
                    .transition(.blurReplace)
            } else {
                content
                    .transition(.blurReplace)
            }
        }
        .animation(.transition, value: showEmptyView)
        .scoopNavigationBarFonts(largeTitleSize:titleSize)
    }
}
