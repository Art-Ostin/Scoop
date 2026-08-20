//
//  TabScrollView.swift
//  Scoop
//
//  Created by Art Ostin on 11/07/2026.

import SwiftUI



//The reusable structure of all TabViews extracted and standardised
struct TabScrollView<Content: View>: View {
    let type: AppTab
    let showEmptyView: Bool
    var name: String = ""
    var position: Binding<ScrollPosition>? = nil
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
        .tabScrollPosition(position)
        .navigationTitle(title)
        .colorBackground()
        .animation(.transition, value: showEmptyView)
        .scrollIndicators(.hidden)
        .hidesBottomScrollEdgeEffect(type == .meet)
        .scoopNavigationBarFonts(title: title, largeTitleSize: titleSize)
    }
}

private extension View {

    ///Only ever ATTACHES a position — a tab that passes one keeps the same branch for its
    ///whole life, so the stable-scroll-view invariant the title styling depends on holds.
    ///Events uses it to rest its scroll at the top behind the accept cover.
    @ViewBuilder
    func tabScrollPosition(_ position: Binding<ScrollPosition>?) -> some View {
        if let position { scrollPosition(position) } else { self }
    }

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
                .padding(.top, Spacing.titlePadding)
                .padding(.bottom, Spacing.clearance)
        }
        .navigationTitle(title)
        .colorBackground()
    }
}
