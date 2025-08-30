//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//
//
import SwiftUI
import Firebase
import UIKit

@main
struct ScoopApp: App {
    
    private let dep: AppDependencies
    @State var appState: AppState = .booting
    
    init() {
        FirebaseApp.configure()
        self.dep = AppDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .appDependencies(dep)
                .task { dep.sessionManager.loadUserAndUserListener(appState: $appState) }
                .environment(\.appState, $appState)
        }
    }
}
