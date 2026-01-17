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

    var userManager: UserManager
    var cacheManager: CacheManaging
    var authManager: AuthManaging
    var storageManager: StorageManaging
    var s: SessionManager
    var defaultsManager: DefaultsManager
    let eventManager: EventManager
    let cycleManager: CycleManager
    
    init(userManager: UserManager, cacheManager: CacheManaging, authManager: AuthManaging, storageManager: StorageManaging, s: SessionManager, eventManager: EventManager, cycleManager: CycleManager, defaultsManager: DefaultsManager) {
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.authManager = authManager
        self.storageManager = storageManager
        self.s = s
        self.defaultsManager = defaultsManager
        self.eventManager = eventManager
        self.cycleManager = cycleManager
    }
    
    func fetchFirstImage() async throws -> UIImage {
        try await cacheManager.fetchFirstImage(profile: user) ?? UIImage()
    }
    
    var user: UserProfile {s.user}
    
    var events: [ProfileModel] { s.pastEvents }
    
    func signOut() {
        try? authManager.signOutAuthUser()
    }
    
    func loadUserImages() async -> [UIImage] {
        return await cacheManager.loadProfileImages([s.user])
    }
}
