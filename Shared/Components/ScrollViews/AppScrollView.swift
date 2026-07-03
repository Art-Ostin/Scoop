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
