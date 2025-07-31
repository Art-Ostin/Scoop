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
        let resized = profile.imagePathURL?.map {
            $0.replacingOccurrences(of: ".jpeg", with: "_1350x1350.jpeg")
        } ?? []
        let urls = resized.compactMap { URL(string: $0) }
        Task { await imageCache.prefetch(urls: urls) }
    }
    func clearUser() {
        user = nil
    }
}
