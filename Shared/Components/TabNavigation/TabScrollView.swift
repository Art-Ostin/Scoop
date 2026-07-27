//
//  TabScrollView.swift
//  Scoop Test
//
//  Created by Art Ostin on 11/07/2026.

import SwiftUI



//The reusable structure of all TabViews extracted and standardised
struct TabScrollView<Content: View>: View {
    let type: AppTab
    let showEmptyView: Bool
    var name: String = ""
    @ViewBuilder let content: Content
    
    
    var titleSize: CGFloat {type == .events && !showEmptyView ? 28 : 32}
    var title: String { type.title(name: name, isEmpty: showEmptyView)}

    var body: some View {
        
        ScrollView {
            if showEmptyView {
                type.placeholderView()
                    .transition(.blurReplace)
            } else {
                content
                    .padding(.top, Spacing.titlePadding)
                    .padding(.bottom, Spacing.clearance)
                    .transition(.blurReplace)
            }
        }
        .navigationTitle(title)
        .colorBackground()
        .animation(.transition, value: showEmptyView)
        .scrollIndicators(.hidden)
        //Meet's cards fly ABOVE the scroll during the zoom transition, where the
        //system's bottom edge fade can't reach them. The landing swaps the flying
        //card for the real one INSIDE the scroll in a single transaction, so the
        //fade would appear in that one frame — a white flash over any card sitting
        //under the tab bar. No fade, nothing to mismatch.
        .hidesBottomScrollEdgeEffect(type == .meet)
        .scoopNavigationBarFonts(largeTitleSize:titleSize)
    }
}

private extension View {
    @ViewBuilder
    func hidesBottomScrollEdgeEffect(_ hidden: Bool) -> some View {
        if hidden, #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            self
        }
    }
}

//Used for EditProfile and Settings View screens
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
