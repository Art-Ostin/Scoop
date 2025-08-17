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
            appState = .app
        } catch {
            appState = .login
        }
    }
    
    
    @MainActor
    func prefetch() async {
        Task {try? await dep.sessionManager.loadprofileRecs()}
        Task {await dep.sessionManager.loadProfileInvites()}
    }
}

