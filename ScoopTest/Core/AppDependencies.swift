//
//  AppDependencies.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//


import Foundation
import SwiftUI

final class AppDependencies {
    
    let authManager: AuthManaging
    let cacheManager: CacheManaging
    let userManager: UserManager
    
    private(set) var storageManager: StorageManaging!
    private(set) var eventManager: EventManager!
    private(set) var cycleManager: CycleManager!
    private(set) var sessionManager: SessionManager!
    
    init(
        authManager: AuthManaging? = nil,
        cacheManager: CacheManaging? = nil,
        userManager: UserManager? = nil,
    ) {
        let auth = authManager ?? AuthManager()
        let cache = cacheManager ?? CacheManager()
        let userManager = userManager ?? UserManager(auth: auth)
        self.authManager = auth
        self.cacheManager = cache
        self.userManager = userManager
    }

    func configure(user: UserProfile) {
        let storage = StorageManager()
        let event = EventManager(user: user, userManager: userManager)
        let cycle = CycleManager(user: user, cacheManager: cacheManager, sessionManager: sessionManager, userManager: userManager)
        let sessionManager = SessionManager(user: user, eventManager: eventManager, cacheManager: cacheManager, userManager: userManager, cycleManager: cycleManager)
        self.storageManager = storage
        self.eventManager = event
        self.cycleManager = cycle
        self.sessionManager = sessionManager
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

