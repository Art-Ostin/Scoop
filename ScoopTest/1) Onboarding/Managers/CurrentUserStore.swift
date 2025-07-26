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
    
    init(auth: AuthenticationManaging, profile: ProfileManaging) {
        self.auth = auth
        self.profileManager = profile
    }
    
    private init() {}
    
    private(set) var user: UserProfile? = nil
    
    func loadUser() async throws {
        let authUser = try auth.getAuthenticatedUser()
        let profile = try await profileManager.getProfile(userId: authUser.uid)
        await MainActor.run {
            self.user = profile
        }
    }
    func clearUser() {
        user = nil
    }
}
