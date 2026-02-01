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
    var imageLoader: ImageLoading
    var authManager: AuthManaging
    var eventRepo: eventRepo
    
    init(sessionManager: SessionManager, imageLoader: ImageLoading, authManager: AuthManaging, eventRepo: eventRepo) {
        self.sessionManager = sessionManager
        self.imageLoader = imageLoader
        self.authManager = authManager
        self.eventRepo = eventRepo
    }
    
    var user: UserProfile {sessionManager.user}
    
    var events: [ProfileModel] { sessionManager.events}
}
