//
//  MatchesViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import UIKit


@Observable class MatchesViewModel {
    
    var userManager: UserManager
    var cacheManager: CacheManaging
    var authManager: AuthManaging
    var storageManager: StorageManaging
    
    
    init(userManager: UserManager, cacheManager: CacheManaging, authManager: AuthManaging, storageManager: StorageManaging) {
        self.userManager = userManager
        self.cacheManager = cacheManager
        self.authManager = authManager
        self.storageManager = storageManager
    }
    
    func fetchFirstImage() async throws -> UIImage {
        let profile = userManager.user
        return try await cacheManager.fetchFirstImage(profile: profile) ?? UIImage()
    }
}
