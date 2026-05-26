//
//  ScoopApp.swift
//  ScoopTest
//
//  Created by Art Ostin on 28/05/2025.
//

import SwiftUI
import Firebase

@main
struct ScoopApp: App {

    private let dep: AppDependencies
    @State private var router = AppRouter()

    init() {
        FirebaseApp.configure()
        self.dep = AppDependencies()
        dep.session.userStream()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dep)
                .environment(router)
        }
    }
}
