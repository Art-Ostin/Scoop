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
    
    let authManager: AuthManaging
    let cacheManager: CacheManaging
    let userManager: UserManager
    let storageManager: StorageManaging
    let eventManager: EventManager
    let cycleManager: CycleManager
    let sessionManager: SessionManager
    
    init(
        authManager: AuthManaging? = nil,
        cacheManager: CacheManaging? = nil,
        userManager: UserManager? = nil
    ) {
        let auth = authManager ?? AuthManager()
        let cache = cacheManager ?? CacheManager()
        let userManager = userManager ?? UserManager(auth: auth)
        let event = EventManager(userManager: userManager)
        let cycle = CycleManager(userManager: userManager)
        let session = SessionManager(eventManager: event, cacheManager: cache, userManager: userManager, cycleManager: cycle, authManager: auth)
        let storage = StorageManager()

        self.authManager = auth
        self.cacheManager = cache
        self.userManager = userManager
        self.sessionManager = session
        self.storageManager = storage
        self.cycleManager = cycle
        self.eventManager = event
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

