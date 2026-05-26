//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//
//
import SwiftUI
import Firebase


//App holistic Architecture: Root view every possible app state (i.e. MainApp, Onboarding, Loading).
//When the app Starts (1) the initial state of Root view is 'Loading' (2) userStream checking if user logged in, launches immedietely
//the user Stream updates the appState which then takes the user to the correct app Mode (i.e. MainApp, blockedAccount, Onboarding...)

let appLaunchStart = ContinuousClock.now

@main
struct ScoopApp: App {

    private let dep: AppDependencies
    private let router = AppRouter()
    
    init() {
        _ = appLaunchStart
        FirebaseApp.configure()
        self.dep = AppDependencies()
        dep.session.userStream() //Start listening to user upon app launch
    }

    var body: some Scene {
        WindowGroup {
             RootView()
                 .environment(dep)
                 .environment(router)
        }
    }
}
