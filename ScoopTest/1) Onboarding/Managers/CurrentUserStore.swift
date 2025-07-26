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
    static let shared = CurrentUserStore()
    private init() {}
    
    private(set) var user: UserProfile? = nil
    
    func loadUser() async throws {
        let authUser = try AuthenticationManager.instance.getAuthenticatedUser()
        let profile = try await ProfileManager.instance.getProfile(userId: authUser.uid)
        await MainActor.run {
            self.user = profile
        }
    }
    func clearUser() {
        user = nil
    }
}
