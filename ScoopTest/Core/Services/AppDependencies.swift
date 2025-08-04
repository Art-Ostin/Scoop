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
    let imageCache: ImageCaching
    let userStore: CurrentUserStore
    let eventManager: EventManager

    
    init(
        authManager: AuthenticationManaging? = nil,
        profileManager: ProfileManaging? = nil,
        storageManager: StorageManaging? = nil,
        imageCache: ImageCaching? = nil,
        eventManager: EventManager? = nil,
        userStore: CurrentUserStore? = nil
    ) {
        let profile = profileManager ?? ProfileManager()
        let auth = authManager ?? AuthenticationManager(profile: profile)
        let storage = storageManager ?? StorageManager()
        let cache = imageCache ?? ImageCache()
        let userStore = userStore ?? CurrentUserStore(auth: auth, profile: profile, imageCache: cache)
        let eventManager = eventManager ?? EventManager(user: userStore)

        self.authManager = auth
        self.profileManager = profile
        self.imageCache = cache
        self.storageManager = storage
        self.userStore = userStore
        self.eventManager = eventManager

        if let manager = profile as? ProfileManager {
            manager.userStore = self.userStore
        }
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

