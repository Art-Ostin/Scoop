//
//  MatchesViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import UIKit

@MainActor
@Observable class MatchesViewModel {
    
    let s: SessionManager
    let storageService: StorageServicing
    let authService: AuthServicing
    let userRepo: UserRepository
    let profilesRepo: ProfilesRepository
    let eventsRepo: EventsRepository
    let imageLoader: ImageLoading
    
    init(s: SessionManager, storageService: StorageServicing, authService: AuthServicing, userRepo: UserRepository, profilesRepo: ProfilesRepository, eventsRepo: EventsRepository, imageLoader: ImageLoading) {
        self.s = s
        self.storageService = storageService
        self.authService = authService
        self.userRepo = userRepo
        self.profilesRepo = profilesRepo
        self.eventsRepo = eventsRepo
        self.imageLoader = imageLoader
    }
        
    func fetchFirstImage() async throws -> UIImage {
        try await imageLoader.fetchFirstImage(profile: user) ?? UIImage()
    }
    
    var user: UserProfile {s.user}
    
    var events: [ProfileModel] { s.pastEvents }
    
    func signOut() {
        try? authService.signOutAuthUser()
    }
    
    func loadUserImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages([s.user])
    }
}
