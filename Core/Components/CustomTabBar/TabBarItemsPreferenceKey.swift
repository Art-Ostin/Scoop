//
//  TabBarItemsPreferenceKey.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI
import Foundation

struct TabBarItemsPreferenceKey: PreferenceKey {
    
    static var defaultValue: [TabBarItem] = []
    
    static func reduce(value: inout [TabBarItem], nextValue: () -> [TabBarItem]) {
        value += nextValue()
    }
}

struct TabBarViewModifier: ViewModifier {
    @Binding var selection: TabBarItem
    let tab: TabBarItem
    func body(content: Content) -> some View {
        content
            .opacity(selection == tab ? 1 : 0)
            .preference(key: TabBarItemsPreferenceKey.self, value: [tab])
    }
}

extension View {
    
    func tabBarItem(_ tab: TabBarItem, selection: Binding<TabBarItem>) -> some View {
        modifier(TabBarViewModifier(selection: selection, tab: tab))
    }
    
}
