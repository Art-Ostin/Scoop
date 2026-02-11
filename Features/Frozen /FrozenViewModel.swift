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
    
    let sessionManager : SessionManager
    let defaults: DefaultsManaging
    let authService: AuthServicing
    let userRepo: UserRepository
    let eventRepo: EventsRepository
    let imageLoader: ImageLoading
    
    init(sessionManager: SessionManager, defaults: DefaultsManaging, authService: AuthServicing, userRepo: UserRepository, eventRepo: EventsRepository, imageLoader: ImageLoading) {
        self.sessionManager = sessionManager
        self.defaults = defaults
        self.authService = authService
        self.userRepo = userRepo
        self.eventRepo = eventRepo
        self.imageLoader = imageLoader
    }
    var user: UserProfile {sessionManager.user}
    var events: [ProfileModel] { sessionManager.events}
}
