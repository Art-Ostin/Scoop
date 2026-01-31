//
//  AppDependencies.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/07/2025.
//


import Foundation
import SwiftUI

final class AppDependencies {
    
    let authService: AuthServicing
    
    let userRepo : UserRepository
    let eventRepo :
    let profilesRepo :
    
    let imageLoader : 
    
    
    
    
    
    
    
    let cacheManager: CacheManaging
    let userManager: UserManager
    let storageManager: StorageManaging
    let eventManager: EventManager
    let defaultsManager: DefaultsManager
    
    @MainActor
    lazy var sessionManager: SessionManager = {
        SessionManager(
            eventManager: eventManager,
            cacheManager: cacheManager,
            userManager: userManager,
            authManager: authManager,
            defaultManager: defaultsManager
        )
    }()
    
    init(
        authManager: AuthManaging? = nil,
        cacheManager: CacheManaging? = nil,
        userManager: UserManager? = nil,
        firestore: FirestoreService? = nil
    ) {
        let auth = authManager ?? AuthManager()
        let cache = cacheManager ?? CacheManager()
        let fs = firestore ?? LiveFirestoreService()
        let userManager = userManager ?? UserManager(auth: auth, fs: fs)
        let storage = StorageManager()
        let event = EventManager(userManager: userManager, fs: fs)
        let defaults = DefaultsManager(defaults: .standard)
        
        self.authManager = auth
        self.cacheManager = cache
        self.userManager = userManager
        self.storageManager = storage
        self.eventManager = event
        self.defaultsManager = defaults
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
