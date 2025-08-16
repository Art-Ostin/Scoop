//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//
//
import SwiftUI
import Firebase

@main
struct ScoopTestApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let deps = AppDependencies()
    
    @State var appState: AppState = .booting
    
    var body: some Scene {
        WindowGroup {
            RootView(state: $appState)
                .appDependencies(deps)
                .task {await Bootstrapper(appState: $appState, dep: deps).start()}
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("configured ze firebase")
        return true
    }
}
