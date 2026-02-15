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
    let storageService: StorageServicing
    let defaultsManager: DefaultsManaging
    let userRepo: UserRepository
    let eventRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let imageLoader: ImageLoading
    let profileLoader: ProfileLoading
    
    @MainActor
    lazy var sessionManager: SessionManager = {
        SessionManager(
            authService: authService,
            defaultsManager: defaultsManager,
            userRepo: userRepo,
            eventsRepo: eventRepo,
            profilesRepo: profilesRepo,
            profileLoader: profileLoader,
            imageLoader: imageLoader)
    }()
    
    init() {
        //1. Building the concrete services that app needs. Storing it as variables.
        let auth = AuthService()
        let fs = FirestoreService()
        let userRepo = UserRepo(fs: fs)
        let imageLoader = ImageLoader()
        
        //2. assigning the variables used through the app with the initialised services
        self.authService = auth
        self.storageService = StorageService()
        self.userRepo = userRepo
        self.eventRepo = EventsRepo(userRepo: userRepo, fs: fs)
        self.profilesRepo = ProfileRepo(fs: fs)
        self.imageLoader = ImageLoader()
        self.profileLoader = ProfileLoader(userRepo: userRepo, imageLoader: imageLoader)
        self.defaultsManager = MainActor.assumeIsolated { DefaultsManager() }
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
