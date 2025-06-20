//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI

@main
struct ScoopTestApp: App {
    
@State private var appState = AppState()
    
  var body: some Scene {
    WindowGroup {
        ZStack{
            Color.background.ignoresSafeArea(edges: .all)
            
            RootView()
                .environment(appState)
        }
    }
  }
}
