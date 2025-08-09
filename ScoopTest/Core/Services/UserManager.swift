//
//  CurrentUserStore.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth

@Observable
class UserManager {
    
    @ObservationIgnored private let auth: AuthenticationManaging
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private let cacheManager: CacheManaging
    
    init(auth: AuthenticationManaging, profile: ProfileManaging, cacheManager: CacheManaging) {
        self.auth = auth
        self.profileManager = profile
        self.cacheManager = cacheManager
    }
    
    private(set) var user: UserProfile? = nil
    
    func loadUser() async throws {
        let authUser = try auth.getAuthenticatedUser()
        let profile = try await profileManager.getProfile(userId: authUser.uid)
        await MainActor.run {
            self.user = profile
        }
        
        Task { await cacheManager.loadProfileImages([profile])}
    }
    func clearUser() {
        user = nil
    }
}





//func loadProfile(_ localProfile: UserProfile) async throws {
//    
//}
