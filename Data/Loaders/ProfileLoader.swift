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
        var models: [PendingProfile] = []
        
        try await withThrowingTaskGroup(of: PendingProfile.self) {group in
            for id in ids {
                group.addTask {
                    try await self.fetchPendingProfile(id)
                }
            }
            for try await model in group {
                models.append(model)
            }
        }
        await imageLoader.addProfileImagesToCache(for: models.map(\.profile))
        return models
    }
    
    private func fetchEventProfile(_ profileId: String, event: UserEvent) async throws -> EventProfile {
        let profile = try await self.userRepo.fetchProfile(userId: profileId)
        let img = try? await self.imageLoader.fetchFirstImage(profile: profile)
        return EventProfile(event: event, profile: profile, image: img)
    }
    
    private func fetchPendingProfile(_ profileId: String) async throws -> PendingProfile {
        let profile = try await self.userRepo.fetchProfile(userId: profileId)
        let img = try await self.imageLoader.fetchFirstImage(profile: profile) ?? UIImage()
        return PendingProfile(profile: profile, image: img)
    }
}

/*
 func fromEvents(_ events: [UserEvent]) async throws -> [ProfileModel] {
     let requests = events.map { LoadRequest(profileId: $0.otherUserId, event: $0) }
     return try await fromRequests(requests)
 }
 
 func fromIds(_ ids: [String]) async throws -> [ProfileModel] {
     let requests = ids.map { LoadRequest(profileId: $0, event: nil) }
     return try await fromRequests(requests)
 }
 
 private func fromRequests(_ requests: [LoadRequest]) async throws -> [ProfileModel] {
     var models: [ProfileModel] = []
     try await withThrowingTaskGroup(of: ProfileModel.self) { group in
         for request in requests {
             group.addTask {
                 try await self.fetchProfileModel(request.profileId, event: request.event)
             }
         }
         
         for try await model in group {
             models.append(model)
         }
     }
     await imageLoader.addProfileImagesToCache(for: models.map(\.profile))
     return models
 }

 */
