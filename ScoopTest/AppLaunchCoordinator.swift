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
        guard await s.loadUser() else { appState = .login ; return }
        Task {
            await s.loadEvents()
            await s.loadInvites()
            await s.loadProfiles()
        }
        appState = .app
    }
}

