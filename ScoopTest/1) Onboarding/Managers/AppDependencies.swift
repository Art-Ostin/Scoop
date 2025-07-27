//
//  AppDependencies.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//


import Foundation
import SwiftUI

@Observable
final class AppDependencies {
    
    let authManager: AuthenticationManaging
    let profileManager: ProfileManaging
    let storageManager: StorageManaging
    let userStore: CurrentUserStore
    
    init(
        authManager: AuthenticationManaging? = nil,
        profileManager: ProfileManaging? = nil,
        storageManager: StorageManaging? = nil
    ) {
        let profile = profileManager ?? ProfileManager()
        let auth = authManager ?? AuthenticationManager(profile: profile)
        let storage = storageManager ?? StorageManager()
        self.authManager = auth
        self.profileManager = profile
        self.storageManager = storage
        self.userStore = CurrentUserStore(auth: auth, profile: profile)
    }
    
    var editProfileViewModel: EditProfileViewModel {
        guard let user = userStore.user else {
            fatalError("User not loaded")
        }
        return EditProfileViewModel(user: user, profile: profileManager, storageManager: storageManager, userHandler: userStore)
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies()
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}

extension View {
    func appDependencies(_ dependencies: AppDependencies) -> some View {
        environment(\.appDependencies, dependencies)
    }
}

