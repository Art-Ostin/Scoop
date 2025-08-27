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
    
    init(authManager: AuthManaging) {
        self.authManager = authManager
    }
    
    func signOut() {
        try? authManager.signOutAuthUser()
    }

}
