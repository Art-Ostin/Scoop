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
    
    init(sessionManager: SessionManager, cacheManager: CacheManaging) {
        self.sessionManager = sessionManager
        self.cacheManager = cacheManager
    }
    
    var user: UserProfile {sessionManager.user}
}
