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
struct ScoopTestApp: App {
    
    private let dep: AppDependencies
    @State var appState: AppState = .booting
    
    init() {
        FirebaseApp.configure()
        self.dep = AppDependencies()
        
        let background = UIColor(red: 0.42, green: 0.4, blue: 0.3, alpha: 1.0)
        UITabBar.appearance().backgroundColor = background
        UINavigationBar.appearance().barTintColor = background    // or configure UINavigationBarAppearance
        UICollectionView.appearance().backgroundColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .appDependencies(dep)
                .environment(\.stateOfApp, $appState)
                .task {
                    let bootstrapper = Bootstrapper(appState: $appState, s: dep.sessionManager)
                    await bootstrapper.start()
            }
        }
    }
}
