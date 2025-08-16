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
    let cacheManager: CacheManaging
    let userManager: UserManager
    let eventManager: EventManager
    let defaultsManager: DefaultsManager
    let weeklyRecsManager: WeeklyRecsManager
    
    init(
        authManager: AuthenticationManaging? = nil,
        profileManager: ProfileManaging? = nil,
        storageManager: StorageManaging? = nil,
        cacheManager: CacheManaging? = nil,
        eventManager: EventManager? = nil,
        userManager: UserManager? = nil,
        defaultsManager: DefaultsManager? = nil,
        weeklyRecsManager: WeeklyRecsManager? = nil

    ) {
        let profile = profileManager ?? FirestoreManager()
        let auth = authManager ?? AuthenticationManager(profile: profile)
        let cache = cacheManager ?? CacheManager()
        let userManager = userManager ?? UserManager(auth: auth, profile: profile, cacheManager: cache)
        let eventManager = eventManager ?? EventManager(user: userManager, profile: profile)
        let storage = storageManager ?? StorageManager(user: userManager)
        let defaultsManager = defaultsManager ?? DefaultsManager(defaults: .standard, firesoreManager: profile, cacheManager: cache)
        let weeklyRecsManager = weeklyRecsManager ?? WeeklyRecsManager(user: userManager)

        self.authManager = auth
        self.profileManager = profile
        self.cacheManager = cache
        self.storageManager = storage
        self.userManager = userManager
        self.eventManager = eventManager
        self.defaultsManager = defaultsManager
        self.weeklyRecsManager = weeklyRecsManager

        if let manager = profile as? FirestoreManager {
            manager.userManager = self.userManager
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

