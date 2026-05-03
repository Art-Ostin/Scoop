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
    let defaults: DefaultsManaging
    
    init(authService: AuthServicing, sessionManager: SessionManager, defaults:DefaultsManaging) {
        self.authService = authService
        self.sessionManager = sessionManager
        self.user = sessionManager.user
        self.defaults = defaults
    }
    
    var preferredMapType: PreferredMapType {
        defaults.preferredMapType
    }
    
    func updatePreferredMapType(_ type: PreferredMapType) {
        defaults.updatePreferredMapType(mapType: type)
    }
    
    func signOut() {
        try? authService.signOutAuthUser()
    }
}
