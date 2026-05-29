//
//  ScrollEdgeTest.swift
//  Scoop Test
//
//  Created by Art Ostin on 28/05/2026.
//

import SwiftUI

struct ScrollEdgeTest: View {

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes      = [.font: UIFont(name: Font.titleFontWeight.bold.rawValue, size: 12)!]
        appearance.largeTitleTextAttributes = [.font: UIFont(name: Font.titleFontWeight.bold.rawValue, size: 12)!]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("Meeting")
                        .font(.title(32, .bold))
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Hello")
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.red.opacity(0.3), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .scrollEdgeIfAvailable()
            .navigationTitle("Hello World")
        }
    }
}

extension View {
    @ViewBuilder
    func scrollEdgeIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
