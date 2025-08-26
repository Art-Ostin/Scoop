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
    let user: UserProfile
    
    init(user: UserProfile, userManager: UserManager, cacheManager: CacheManaging, authManager: AuthManaging, storageManager: StorageManaging, s: SessionManager, defaultsManager: DefaultsManager) {
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.authManager = authManager
        self.storageManager = storageManager
        self.s = s
        self.defaultsManager = defaultsManager
        self.user = user
    }
    
    func fetchFirstImage() async throws -> UIImage {
        try await cacheManager.fetchFirstImage(profile: user) ?? UIImage()
    }
    
    
    func signOut() {
        try? authManager.signOutAuthUser()
    }
}
