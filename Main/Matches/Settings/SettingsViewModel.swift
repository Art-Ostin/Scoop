//
//  SettingsViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/08/2025.
//

import Foundation


@MainActor
@Observable class SettingsViewModel {
    
    var authManager: AuthManaging
    var sessionManager: SessionManager
    
    let user: UserProfile
    
    init(authManager: AuthManaging, sessionManager: SessionManager) {
        self.authManager = authManager
        self.sessionManager = sessionManager
        self.user = sessionManager.user
    }
    
    func signOut() {
        try? authManager.signOutAuthUser()
        sessionManager.stopSession()
    }

}
