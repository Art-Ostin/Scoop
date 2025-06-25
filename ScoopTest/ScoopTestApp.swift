//
//  ScoopTestApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI
import Firebase


@main
struct ScoopTestApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    
@State private var appState = AppState()
    
  var body: some Scene {
    WindowGroup {
        ZStack{
//            Color.background.ignoresSafeArea(edges: .all)
            RootView()
                .environment(appState)
//                .offWhite()
        }
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
