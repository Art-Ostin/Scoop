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
    
    let session : Session
    let defaults: DefaultsManaging
    let authService: AuthServicing
    let userRepo: UserRepository
    let eventRepo: EventsRepository
    let chatRepo: ChatRepository
    let imageLoader: ImageLoading
    
    init(session: Session, defaults: DefaultsManaging, authService: AuthServicing, userRepo: UserRepository, chatRepo: ChatRepository, eventRepo: EventsRepository, imageLoader: ImageLoading) {
        self.session = session
        self.defaults = defaults
        self.authService = authService
        self.userRepo = userRepo
        self.eventRepo = eventRepo
        self.chatRepo = chatRepo
        self.imageLoader = imageLoader
    }
    var user: UserProfile {session.user}
    var events: [EventProfile] { session.events}
}
