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
    
    var s: SessionManager
    
    
    
    
    var userRepo: userRepo
    var imageLoader: ImageLoading
    var authService: AuthServicing
    var storageManager: StorageManaging
    var s: SessionManager
    var defaultsManager: DefaultsManager
    let eventRepo: eventRepo
    let cycleManager: CycleManager
    
    init(userRepo: userRepo, imageLoader: ImageLoading, authService: AuthServicing, storageManager: StorageManaging, s: SessionManager, eventRepo: eventRepo, cycleManager: CycleManager, defaultsManager: DefaultsManager) {
        self.userRepo = userRepo
        self.imageLoader = imageLoader
        self.authService = authService
        self.storageManager = storageManager
        self.s = s
        self.defaultsManager = defaultsManager
        self.eventRepo = eventRepo
        self.cycleManager = cycleManager
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
