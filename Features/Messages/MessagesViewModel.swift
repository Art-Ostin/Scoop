//
//  MatchesViewModel.swift
//  Scoop
//
//  Created by Art Ostin on 19/08/2025.
//

import Foundation
import UIKit

@MainActor
@Observable class MessagesViewModel {
    
    //Injected
    let session: Session
    let storageService: StorageServicing
    let defaults: DefaultsManaging
    let authService: AuthServicing
    let userRepo: UserRepository
    let profilesRepo: ProfilesRepository
    let chatRepo: ChatRepository
    let eventsRepo: EventsRepository
    let imageLoader: ImageLoading

    init(session: Session, storageService: StorageServicing, defaults: DefaultsManaging, authService: AuthServicing, chatRepo: ChatRepository, userRepo: UserRepository, profilesRepo: ProfilesRepository, eventsRepo: EventsRepository, imageLoader: ImageLoading) {
        self.session = session
        self.storageService = storageService
        self.authService = authService
        self.chatRepo = chatRepo
        self.userRepo = userRepo
        self.profilesRepo = profilesRepo
        self.eventsRepo = eventsRepo
        self.imageLoader = imageLoader
        self.defaults = defaults
    }

    var user: UserProfile { session.user }
    var events: [EventProfile] { session.pastEvents }

    func fetchFirstImage() async throws -> UIImage {
        try await imageLoader.fetchFirstImage(profile: user) ?? UIImage()
    }

    func fetchFirstProfileImage(profile: UserProfile) async throws -> UIImage {
        try await imageLoader.fetchFirstImage(profile: profile) ?? UIImage()
    }

    func signOut() {
        try? authService.signOutAuthUser()
    }

    func loadUserImages() async -> [UIImage] {
        return await imageLoader.loadProfileImages(session.user)
    }
    
    func fetchUserMessages(eventId: String) async throws -> [ChatMessage] {
            if let messages = try? await chatRepo.fetchMessages(eventId: eventId) {
                return messages
            } else {
                return []
            }
    }
    
    func readMessages(userEventId: String, userId: String) async throws {
        try await eventsRepo.readRecentMessages(userId: userId, userEventId: userEventId)
    }
}

