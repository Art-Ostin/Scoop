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
    
    
    init(userManager: UserManager, cacheManager: CacheManaging, authManager: AuthManaging, storageManager: StorageManaging, s: SessionManager) {
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.authManager = authManager
        self.storageManager = storageManager
        self.s = s
    }
    
    func fetchFirstImage() async throws -> UIImage {
        let profile = s.user
        return try await cacheManager.fetchFirstImage(profile: profile) ?? UIImage()
    }
    
    var user: UserProfile { s.user }
}
