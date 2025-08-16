//
//  AppBootstrapper.swift
//  ScoopTest
//
//  Created by Art Ostin on 15/08/2025.
//

import SwiftUI

@MainActor
struct Bootstrapper {
    
    @Binding var appState: AppState
    
    let dep: AppDependencies
    
    func start () async {
        do {
            _ = try dep.authManager.getAuthenticatedUser()
            print("User is auth")
            appState = .app
        } catch {
            print("User is not auth")
            appState = .login
        }
    }
}
