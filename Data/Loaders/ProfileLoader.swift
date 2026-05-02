//
//  ProfileModelBuilder.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation
import SwiftUI

final class ProfileLoader: ProfileLoading {
    
    private struct LoadRequest {
        let profileId: String
        let event: UserEvent?
    }
    
    private let userRepo: UserRepository
    private let imageLoader: ImageLoading
    
    init(userRepo: UserRepository, imageLoader: ImageLoading) {
        self.userRepo = userRepo
        self.imageLoader = imageLoader
    }
    
    func fromEvents(_ events: [UserEvent]) async throws -> [EventProfile] {
        var models: [EventProfile] = []
        
        try await withThrowingTaskGroup(of: EventProfile.self) {group in
            for event in events {
                group.addTask {
                    try await self.fetchEventProfile(event.otherUserId, event: event)
                }
            }
            for try await model in group {
                models.append(model)
            }
        }
        await imageLoader.addProfileImagesToCache(for: models.map(\.profile))
        return models
    }
    
    func fromIds(_ ids: [String]) async throws -> [PendingProfile] {
        var profiles: [UserProfile] = []

        try await withThrowingTaskGroup(of: UserProfile.self) { group in
            for id in ids {
                group.addTask {
                    try await self.userRepo.fetchProfile(userId: id)
                }
            }
            for try await profile in group {
                profiles.append(profile)
            }
        }

        await imageLoader.addProfileImagesToCache(for: profiles)
        return profiles.map { PendingProfile(profile: $0, image: nil) }
    }

    private func fetchEventProfile(_ profileId: String, event: UserEvent) async throws -> EventProfile {
        let profile = try await self.userRepo.fetchProfile(userId: profileId)
        let img = try await self.imageLoader.fetchFirstImage(profile: profile)
        return EventProfile(event: event, profile: profile, image: img)
    }
}

/*
 
 private func fetchPendingProfile(_ profileId: String) async throws -> PendingProfile {
     let clock = ContinuousClock()
     let start = clock.now
     
     let profile = try await self.userRepo.fetchProfile(userId: profileId)
     let img = try await self.imageLoader.fetchFirstImage(profile: profile) ?? UIImage()
     let duration = start.duration(to: clock.now)
     print("Time taken to fetch Pending Profile: \(duration)")
     return PendingProfile(profile: profile, image: img)
 }

 */
