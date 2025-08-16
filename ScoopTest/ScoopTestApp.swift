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
    private let session: AppSession
    
    init () {
        self.session = AppSession(dep: deps)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .appDependencies(deps)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("confifured ze firebase")
        return true
    }
}
