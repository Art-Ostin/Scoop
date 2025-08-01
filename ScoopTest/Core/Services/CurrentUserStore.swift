//
//  CurrentUserStore.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//

import Foundation
import FirebaseAuth

@Observable
class CurrentUserStore {
    
    @ObservationIgnored private let auth: AuthenticationManaging
    @ObservationIgnored private let profileManager: ProfileManaging
    @ObservationIgnored private let imageCache: ImageCaching
    
    init(auth: AuthenticationManaging, profile: ProfileManaging, imageCache: ImageCaching) {
        self.auth = auth
        self.profileManager = profile
        self.imageCache = imageCache
    }
    private(set) var user: UserProfile? = nil
    
    func loadUser() async throws {
        let authUser = try auth.getAuthenticatedUser()
        let profile = try await profileManager.getProfile(userId: authUser.uid)
        await MainActor.run {
            self.user = profile
        }
        let urls = profile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        Task { await imageCache.prefetch(urls: urls) }
    }
    
    func loadProfile(_ localProfile: UserProfile) async throws {
        let urls = localProfile.imagePathURL?.compactMap { URL(string: $0) } ?? []
        Task { await imageCache.prefetch(urls: urls) }
    }
     
    
    
    func clearUser() {
        user = nil
    }
}
