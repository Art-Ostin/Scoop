//
//  FrozenHomeViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 24/01/2026.
//

import Foundation

@MainActor
@Observable
class FrozenViewModel {
    
    var sessionManager : SessionManager
    var cacheManager: CacheManaging
    var authManager: AuthManaging
    
    init(sessionManager: SessionManager, cacheManager: CacheManaging, authManager: AuthManaging) {
        self.sessionManager = sessionManager
        self.cacheManager = cacheManager
        self.authManager = authManager
    }
    
    var user: UserProfile {sessionManager.user}
    
    var events: [ProfileModel] { sessionManager.events}
    
}
