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

    let authService: AuthServicing
    let storageService: StorageServicing
    let defaultsManager: DefaultsManaging
    let userRepo: UserRepository
    let eventRepo: EventsRepository
    let profilesRepo: ProfilesRepository
    let imageLoader: ImageLoading
    let profileLoader: ProfileLoading
    let chatRepo: ChatRepository

    @ObservationIgnored @MainActor
    let notifications: InAppNotificationCenter

    @ObservationIgnored @MainActor
    lazy var session: Session = {
        Session(
            authService: authService,
            defaultsManager: defaultsManager,
            userRepo: userRepo,
            eventsRepo: eventRepo,
            profilesRepo: profilesRepo,
            chatRepo: chatRepo,
            profileLoader: profileLoader,
            imageLoader: imageLoader,
            notifications: notifications)
    }()

    init() {
        //1. Building the concrete services that app needs. Storing it as variables.
        let auth = AuthService()
        let fs = FirestoreService()
        fs.warmUp()
        let userRepo = UserRepo(fs: fs)
        let imageLoader = ImageLoader()
        let eventsRepo = EventsRepo(fs: fs)

        //2. assigning the variables used through the app with the initialised services
        self.authService = auth
        self.storageService = StorageService()
        self.userRepo = userRepo
        self.eventRepo = eventsRepo
        self.imageLoader = imageLoader
        self.profilesRepo = ProfileRepo(fs: fs)
        self.profileLoader = ProfileLoader(userRepo: userRepo, imageLoader: imageLoader)
        self.defaultsManager = MainActor.assumeIsolated { DefaultsManager() }
        self.chatRepo = ChatRepo(eventsRepo: eventsRepo, fs: fs)
        self.notifications = MainActor.assumeIsolated { InAppNotificationCenter() }
    }
}

