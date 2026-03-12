//
//  ProfileModelBuilder.swift
//  Scoop
//
//  Created by Art Ostin on 03/09/2025.
//

import Foundation

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
    
    func fetchProfileModel(_ profileId: String, event: UserEvent? = nil) async throws -> ProfileModel {
        let profile = try await self.userRepo.fetchProfile(userId: profileId)
        let img = try? await self.imageLoader.fetchFirstImage(profile: profile)
        return ProfileModel(event: event, profile: profile, image: img)
    }
}
