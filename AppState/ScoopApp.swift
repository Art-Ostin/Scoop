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

//App holistic Architecture: Root view every possible app state (i.e. MainApp, Onboarding, Loading).
//When the app Starts (1) the initial state of Root view is 'Loading' (2) userStream checking if user logged in, launches immedietely
//the user Stream updates the appState which then takes the user to the correct app Mode (i.e. MainApp, blockedAccount, Onboarding...)

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
                 .onAppear { dep.sessionManager.userStream(appState: $appState) }
                 .environment(\.appState, $appState)
        }
    }
}
