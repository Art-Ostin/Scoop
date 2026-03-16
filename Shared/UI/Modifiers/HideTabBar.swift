//
//  HideTabBar.swift
//  Scoop
//
//  Created by Art Ostin on 16/03/2026.
//

import SwiftUI

extension View {
    
    func hideTabBar() -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
            .tabBarHidden(true) // This is custom Tool bar hidden
    }
}
