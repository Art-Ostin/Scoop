//
//  TabBarItemsPreferenceKey.swift
//  Scoop
//
//  Created by Art Ostin on 05/09/2025.
//

import SwiftUI

struct TabBarVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct TabBarVisibilityModifier: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        content.preference(key: TabBarVisibilityPreferenceKey.self, value: hidden)
    }
}

extension View {
    func tabBarHidden(_ hidden: Bool) -> some View {
        modifier(TabBarVisibilityModifier(hidden: hidden))
    }
}
