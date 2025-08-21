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
    
    let s: SessionManager
    
    func start () async {

        let state = await s.loadUser()
        if state == .app {
            Task {
                print("prefetch was called")
                await s.loadEvents()
                await s.loadInvites()
                await s.loadProfiles()
            }
            appState = .app
            return
        } else if state == .createAccount {
            appState = .createAccount
            return
        } else if state == .login {
            appState = .login
        }
    }
}

