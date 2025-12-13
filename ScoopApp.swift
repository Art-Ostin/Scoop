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

import CoreText

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
                .task { dep.sessionManager.userStream(appState: $appState) }
                .environment(\.appState, $appState)
        }
    }
}

//Text("HEllo world") Commit on new savepoint
