//
//  SettingsViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 27/08/2025.
//

import Foundation


@MainActor
@Observable class SettingsViewModel {
    
    //Injected
    let authService: AuthServicing
    let session: Session
    let user: UserProfile
    let defaults: DefaultsManaging
    
    init(authService: AuthServicing, session: Session, defaults:DefaultsManaging) {
        self.authService = authService
        self.session = session
        self.user = session.user
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
