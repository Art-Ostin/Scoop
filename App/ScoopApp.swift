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

    @State private var dep: AppDependencies
    @State private var router = AppRouter()

    init() {
        FirebaseApp.configure()
        let dep = AppDependencies()
        _dep = State(initialValue: dep)
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
