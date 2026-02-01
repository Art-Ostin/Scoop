//
//  SettingsViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 27/08/2025.
//

import Foundation


@MainActor
@Observable class SettingsViewModel {
    
    var authService: AuthServicing
    var sessionManager: SessionManager
    
    let user: UserProfile
    
    init(authService: AuthServicing, sessionManager: SessionManager) {
        self.authService = authService
        self.sessionManager = sessionManager
        self.user = sessionManager.user
    }
    
    func signOut() {
        try? authService.signOutAuthUser()
        sessionManager.stopSession()
    }
}
