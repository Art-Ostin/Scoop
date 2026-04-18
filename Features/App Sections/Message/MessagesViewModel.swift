//
//  MatchesViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import UIKit

@MainActor
@Observable class MessagesViewModel {
    
    let s: SessionManager
    let storageService: StorageServicing
    let defaults: DefaultsManaging
    let authService: AuthServicing
    let userRepo: UserRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository
    let eventsRepo: EventsRepository
    let imageLoader: ImageLoading
    
    init(s: SessionManager, storageService: StorageServicing, defaults: DefaultsManaging, authService: AuthServicing, chatRepo: ChatRepository, userRepo: UserRepository, profilesRepo: ProfilesRepository, eventsRepo: EventsRepository, imageLoader: ImageLoading) {
        self.s = s
        self.storageService = storageService
        self.authService = authService
        self.chatRepo = chatRepo
        self.userRepo = userRepo
        self.profilesRepo = profilesRepo
        self.eventsRepo = eventsRepo
        self.imageLoader = imageLoader
        self.defaults = defaults
    }
        
    func fetchFirstImage() async throws -> UIImage {
        try await imageLoader.fetchFirstImage(profile: user) ?? UIImage()
    }
    
    func fetchFirstProfileImage(profile: UserProfile) async throws -> UIImage {
        try await imageLoader.fetchFirstImage(profile: profile) ?? UIImage()
    }
    
    var user: UserProfile {s.user}
    
    var events: [EventProfile] { s.pastEvents }
    
    func signOut() {
        try? authService.signOutAuthUser()
    }
    
    func loadUserImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages(s.user)
    }
}
