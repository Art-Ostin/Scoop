//
//  HideTabBar.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

extension View {
    func hideTabBar(hideBar: Bool = true) -> some View {
        self
            .toolbar(hideBar ? .hidden : .visible, for: .tabBar)
            .tabBarHidden(hideBar) // This is custom Tool bar hidden
    }
}
