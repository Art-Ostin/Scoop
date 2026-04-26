//
//  TabSelectionKey.swift
//  ScoopTest
//
//  Created by Art Ostin on 14/08/2025.
//

import SwiftUI

private struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<TabBarItem> = .constant(.meet)
}

extension EnvironmentValues {
    var tabSelection: Binding<TabBarItem> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

private struct AppStateKey: EnvironmentKey {
    static let defaultValue: Binding<AppState> = .constant(.booting)
}

extension EnvironmentValues {
    var appState: Binding<AppState> {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
