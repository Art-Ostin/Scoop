//
//  LimitedAccessViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 01/09/2025.
//

import SwiftUI

@Observable class OnboardingViewModel {
    
    
    var authManager: AuthManaging
    var defaultsManager: DefaultsManager
    
    init(authManager: AuthManaging, defaultsManager: DefaultsManager) {
        self.authManager = authManager
        self.defaultsManager = defaultsManager
    }
    
    func signOut() async throws {
        try await authManager.deleteAuthUser()
        defaultsManager.deleteDefaults()
    }
}

